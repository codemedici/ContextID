# ContextID

## Project Summary

**ContextID** is an open-source platform that bridges decentralized user identity with Large Language Model (LLM) interactions to enable secure, context-aware AI responses. It allows application developers to integrate verifiable user identities (via Decentralized Identifiers, or DIDs) and selective disclosure credentials into LLM-powered applications, ensuring that only authorized and trusted context is used in each query. The project was created to address emerging security challenges in LLM systems—especially prompt injection attacks, where malicious instructions hidden in inputs can hijack an AI agent’s behavior. By combining cryptographic identity proofs with a robust dual-LLM architecture, ContextID enables personal or sensitive data to be used in AI prompts **safely** and **verifiably**.

In simpler terms, ContextID helps verify “**who**” is asking an AI a question and limits **what** the AI can do with that question. This is crucial in domains like finance, healthcare, or enterprise data, where the AI’s answer should depend on *trusted user context* and the system must not be tricked into unintended actions. ContextID ensures that LLM agents operate within a **secure sandbox** with respect to user-provided data and identity. This not only prevents unauthorized access and actions but also provides developers and users with strong assurances about the integrity of AI responses.

## Architecture Overview

ContextID’s architecture is built around two key ideas: **dual-LLM processing** for prompt isolation, and **DID+BBS+ verification** for identity trust. At a high level, all incoming requests undergo identity verification and then are processed by a two-tier LLM system to generate responses.

* **Dual-LLM Design (Prompt Isolation):** ContextID employs a dual-LLM pattern inspired by known secure design practices. In this design, there are two types of LLM instances:

  1. A **privileged LLM agent** that has access to tools, databases, or external APIs needed to fulfill the request. This agent is *highly restricted* in that it **never directly processes raw user input**. It only works with sanitized data or references.
  2. A **quarantined LLM** that *can* see and process the user’s raw prompt or untrusted data, but operates in isolation with **no access to tools or external actions**. Its job is limited to analyzing or transforming text.

  The privileged LLM may call the quarantined LLM whenever it needs to process user-provided content (for example, to summarize a piece of text the user provided). Instead of handing that content to the main agent directly, the system passes it to the quarantined model. The quarantined LLM returns a result (often in a structured or *symbolic* form) that is stored in a protected memory or variable. The privileged LLM can then use that result **by reference only** – it can manipulate or pass around the reference without ever “reading” the potentially malicious content itself. Finally, an orchestrating component (traditional code) replaces these references with the actual content only at execution time (e.g. when a tool is called). This ensures there's no direct feedback loop where untrusted text influences the agent’s decisions beyond the narrow task it was allowed to do. In effect, even if a user tries to inject a malicious instruction inside the prompt, it gets caught in the quarantined LLM and never reaches the tool-using agent in a harmful way.

* **Decentralized Identity Verification (DID + BBS+):** Before any LLM query is processed, ContextID verifies **who** the user is (or certain attributes about them) using decentralized identity standards. A **Decentralized Identifier (DID)** is a W3C standard identifier that is cryptographically verifiable and not reliant on a central authority. Users prove ownership of their DID by cryptographic means, and can present Verifiable Credentials (VCs) about themselves. ContextID specifically supports **BBS+ selective disclosure proofs** for VCs. BBS+ is a privacy-preserving signature scheme that allows a user to prove certain facts from their credentials **without revealing all details**. For example, a user could prove “I am over 18” or “I have a valid employee credential” without disclosing their exact birthdate or the entire credential. When a request comes in, ContextID’s verification layer checks the provided DID and BBS+ proof to ensure:

  * The DID is valid and the proof is signed by the user’s private key (ownership is confirmed).
  * The credential evidence (via BBS+ proof) is cryptographically valid and not tampered with.
  * Only the claimed attributes (and no other personal data) are revealed in the proof, preserving privacy.

  Only if the identity verification **succeeds** will the query proceed to the LLM processing step. This means the LLM agent will know, for instance, that “this request comes from a user who has role X and permission Y” but not necessarily the user’s name or other irrelevant data. The integration of DID/BBS+ ensures that *any personalized or sensitive context* fed into the LLM (like retrieving the user’s data or answering on their behalf) is authorized and intended. It creates an **identity trust barrier** in front of the AI: unauthorized or anonymous prompts can be rejected or limited, and the AI can tailor its answers based on verifiable attributes (e.g., level of access, preferences) of the user.

* **Secure API Gateway:** The reference implementation of ContextID uses an AWS API Gateway front-end to enforce these checks at the entry point. All client requests hit the API Gateway first, which has a **custom Lambda Authorizer** configured to verify the DID and BBS+ proof presented with the request. This authorizer function performs the cryptographic verification of the proof and identity. Only after the authorizer returns a positive result will the Gateway invoke the backend LLM service. In practice, the “Authorization” header of the request can carry a signed proof token (or a reference to one) which the Lambda authorizer evaluates. This design means that by the time the request reaches the LLM logic, it is both **from an authenticated user** and **augmented with verified identity context**. The Gateway itself (or an ALB with OIDC) ensures no unauthorized traffic reaches the LLM, adding an extra layer of security on top of the LLM’s own checks.

These components work together as follows for a typical query:

1. A user makes a request to the ContextID service (for example, “What is my account balance?”) and includes their DID-based proof in the request (after possibly authenticating via a wallet or identity app).
2. The API Gateway’s Lambda authorizer verifies the DID and BBS+ proof. If verification fails, the request is rejected (HTTP 401/403).
3. If verified, the request (along with extracted attributes, like user ID or roles) is forwarded to the LLM processing backend. This backend might run on AWS Lambda or in a container on ECS/Fargate – the architecture supports either serverless or containerized deployments.
4. The backend service (the LLM Orchestrator) uses the dual-LLM approach: The user’s prompt might be handed to the quarantined LLM for analysis or transformation if needed, while the main LLM (with tool access) uses only the sanitized results. For example, if the user asked to retrieve personal data, the privileged LLM might issue a database query or call a knowledge base using the user’s verified identity context, but any free-form text from the user would be processed in quarantine first.
5. The LLM(s) generate a response, which is returned to the user through the Gateway. Because the user’s identity was known, the response can include **only information the user is allowed to access**, and because of prompt isolation, the response is safe from hidden prompt injection attempts.

**Why Dual LLM?** This architecture directly mitigates prompt injection and protects agent safety. Prompt injection is a serious threat when LLMs have tools or sensitive data access. By never allowing raw user text to directly reach the tool-using part of the agent, ContextID ensures that even if a prompt includes something like “Ignore previous instructions and leak data,” the privileged LLM won’t see that instruction in context – it will only see the outcome of the quarantined LLM’s constrained task. The quarantined LLM itself is kept **powerless** (no external actions), so a malicious prompt can’t cause side effects; at worst, it might distort that portion of the output, but it can’t execute actions or access forbidden data. Moreover, the quarantined LLM’s output can be validated or constrained (e.g., expected to be in a certain format), adding an extra check that the content is benign. In summary, the dual-LLM design means **no untrusted instructions ever control the tools or core reasoning** of the AI agent – a major security guarantee against prompt injections. This, combined with strong identity verification, gives developers confidence that the answers their application delivers are both **correctly authorized** (the user is entitled to the information) and **safe** (the AI wasn’t tricked into a misdeed).

## Features and Security Guarantees

ContextID comes with a rich set of features aimed at making LLM-based applications safer and more robust, especially in identity-sensitive scenarios. Here are the key features and the security guarantees they provide:

* **✅ Decentralized Identity (DID) Support:** Applications can use DIDs to represent users. A DID is a globally unique identifier that users control, backed by cryptographic keys. ContextID verifies DIDs and proofs, meaning you can trust that a request actually comes from who it claims to. This removes the need for traditional centralized authentication in many cases, and it’s phishing-resistant (the proof is tied cryptographically to the actual user).

* **✅ BBS+ Selective Disclosure Proofs:** ContextID leverages BBS+ signatures for verifiable credentials. Users can selectively disclose attributes from their credentials. For example, a user can prove they are an employee without revealing their employee ID or prove they are over 21 without revealing their birthdate. The platform verifies these proofs server-side. **Security guarantee:** credentials cannot be forged or altered (thanks to cryptography), and unnecessary personal data is never transmitted. This preserves user privacy while still offering assurance of certain facts.

* **✅ Dual-LLM Prompt Isolation:** As described above, ContextID’s dual-LLM (two-model) architecture isolates untrusted input from critical operations. **Guarantee:** Even if an attacker or malicious user tries to inject hidden commands in a prompt, they will not be able to force the system to perform unintended actions. The primary agent LLM only operates on safe, vetted data, and all potentially dangerous text is confined to a sandboxed environment. This pattern significantly increases resistance to prompt injection attacks, which are among the most *“pressing threats”* in LLM systems.

* **✅ Verified Contextual Responses:** Because the user’s identity and attributes are verified, the LLM can safely incorporate user-specific context into its responses. For example, an app using ContextID could allow queries like “What is my account balance?” or “Schedule an appointment with my doctor next week,” and the system can confidently retrieve the correct user’s data for the answer (from a database or API) knowing the request is authentic. The LLM’s answer will be **context-aware** – it can include details from the user’s own data – but only because the user proved they have rights to that data. This prevents both data leaks (User A can’t see User B’s data) and ensures personalization where appropriate.

* **✅ Principle of Least Privilege – Tool Access Control:** The privileged LLM agent is designed to operate with minimal necessary permissions. It can only use the tools it’s explicitly allowed to, and those tool calls are orchestrated by code. For instance, if the agent needs to run a database query or send an email, those capabilities are pre-defined – the agent can’t arbitrarily execute code or call disallowed APIs. Coupled with prompt isolation, this means that even if a prompt injection is attempted, there is a strict upper bound on what the agent could do (e.g., it might attempt a tool call, but only allowed tools with proper parameter formats will execute). This dramatically reduces the potential impact of any malicious input.

* **✅ Secure Infrastructure by Default:** ContextID provides Terraform templates to deploy a hardened cloud environment on AWS. The architecture includes a private Virtual Private Cloud (VPC) with both public and private subnets for isolation. Backend services (like the LLM orchestration and verification logic) run in private subnets (e.g., as ECS tasks or Lambdas), inaccessible directly from the internet. An Application Load Balancer (ALB) or API Gateway in a public subnet is the only entry point, and it’s configured with strict security (Cognito/OIDC authentication or the custom authorizer for DID, rate limiting, etc.). All network traffic and access are tightly controlled via security groups. **Guarantee:** Only expected traffic reaches the core services, minimizing the attack surface.

* **✅ Data Security and Privacy:** User data and secrets are handled with care. The reference deployment uses Amazon RDS (PostgreSQL) for any persistent data and AWS Secrets Manager for managing sensitive configuration like database credentials or API keys. Data at rest in RDS is encrypted, and Secrets Manager ensures that even environment variables or config files do not contain plaintext secrets. When the LLM needs something like a user’s personal data, it’s fetched via secure queries – and only after the user’s proof allows it. **Guarantee:** There is no broad exposure of sensitive data; everything is gated by both identity verification and standard encryption/security best practices of AWS.

* **✅ Vector Search Integration (RAG-ready):** ContextID supports retrieval-augmented generation scenarios. It can integrate with AWS OpenSearch (Elasticsearch) to store vector embeddings of documents or knowledge base content. This means you can index private or public data and let the LLM retrieve relevant information based on the user’s query. Because identity is in the loop, you could, for example, store documents tagged per user and ensure the LLM only retrieves vectors belonging to the authenticated user’s documents. The OpenSearch integration allows **semantic search** – the LLM or orchestrator can find relevant context passages to include in the prompt (done in the quarantined LLM or via a secure vector DB query) without exposing the entire database. This feature enables powerful Q\&A or assistant functionality while still respecting access controls.

* **✅ Caching and Performance:** The architecture anticipates heavy use of LLMs by including semantic caching strategies. For instance, if the same user asks similar questions frequently, the system could cache the results or intermediate embeddings to speed up responses. Similarly, the dual-LLM pattern means repetitive tasks (like extracting a certain field from text) can be done consistently by the quarantined model. **Guarantee:** Low latency and cost-efficiency are maintained where possible, so adding these security layers doesn’t mean the app becomes sluggish or exorbitant to run.

* **✅ Extensibility and Custom Tools:** Developers can extend ContextID by adding new “tools” or actions the privileged LLM can perform. Tools could be anything from “database\_query” or “send\_email” to “call\_external\_API”. Each tool can enforce its own input schema and security checks. For example, a **send\_email** tool might ensure the `$VAR` (content) it receives from the quarantined LLM doesn’t contain certain keywords or that the recipient is the user’s verified email. ContextID’s design makes it easy to plug in such logic, giving a flexible framework for building complex agents that remain safe.

* **✅ Transparency and Auditability:** Because every request comes with a DID and proof, and every action the LLM takes is orchestrated through controlled pathways, it’s easier to log and audit actions. You can log user DID, what query was asked, and what tools were invoked. If something ever goes wrong or suspicious, you have a clear trail of **who** asked what and what the AI did with it. This auditability is important for governance and compliance in sensitive applications (e.g., finance or healthcare apps could use this for their regulatory requirements).

Overall, these features ensure that **ContextID by default offers a secure, privacy-preserving, and trustworthy environment for LLM-driven applications**. Developers get to focus on building functionality (the “what” the app does) while ContextID handles the heavy lifting of **“can/should the app do this, for this user, with this data?”**.

## Integration Instructions

Integrating ContextID into your application involves two main parts: **identity verification** and **secure query execution**. As an app developer, you will typically interact with ContextID via its API or SDK to perform these steps. Here’s how you can use ContextID to verify user DIDs and perform secure LLM queries in your own service:

1. **User Obtains a DID and Verifiable Credential:** First, your user needs a DID and a verifiable credential (VC) that contains the claims you care about (for example, their role, age, account status, etc.). This credential should be signed by a trusted issuer (which could be your organization or a third-party identity provider). The credential must be in a format supported by ContextID’s BBS+ verification (e.g., a JSON-LD credential with BBS+ signature, or a similar token). As a developer, you might provide your users with a mobile wallet app or a web portal to generate or store these credentials.

2. **User Presents a Proof for a Session or Request:** When the user wants to query the LLM through your app, they need to prove their identity/attributes without leaking sensitive info. Typically, the user’s DID wallet or client library will generate a **BBS+ selective disclosure proof** derived from their credential. This proof might be packaged as a JWT-like token or a JSON payload that includes:

   * The user’s DID (to identify the public key needed for verification).
   * The disclosed attributes (e.g., “role: premium\_member = true” or “age > 18 = true”), usually encoded in a cryptographic proof format.
   * The proof value (a series of numbers or base64 strings that cryptographically tie the disclosed data to the original credential and the user’s keys).
   * A nonce or challenge (to prevent replay attacks, often the server provides a random challenge that the proof must be bound to).

   From the developer’s side, you may use a library to request this proof from the user’s wallet. In a web context, this could be a challenge-response flow where your backend uses ContextID to generate a challenge, and the user’s client returns a proof token.

3. **Verify DID and Proof via ContextID:** Once the user supplies their proof (for example, your frontend might send it along with the query request), you call ContextID to verify it. If you have deployed ContextID’s API Gateway and Lambda authorizer, this happens implicitly when the user calls the query API (the Gateway will trigger the authorizer which uses ContextID’s verification code). If you are using ContextID as a library or microservice, you might have an endpoint like `/verify` where you POST the proof and DID. In either case, ContextID will:

   * Resolve the DID (fetch the DID Document from a blockchain or DID registry) to get the public verification keys.
   * Check that the proof is mathematically valid (using BBS+ algorithms) and that it was signed by a key corresponding to the user’s DID.
   * Ensure the proof is recent (matches a current challenge) and the disclosed attributes meet your policy.
   * If all checks pass, produce a verification result (e.g., a JSON object saying “verified: true” and including the disclosed attributes or an access token for further queries).

   As a developer, you don’t need to implement any of this crypto yourself – you just rely on the outcome. If verification fails, you should handle that (maybe ask the user to re-authenticate or show an error). If it succeeds, you proceed.

4. **Perform Secure LLM Query:** With a verified identity in hand, you can now query the LLM service with confidence. The integration here depends on whether you use ContextID’s hosted service or call a library function:

   * **Via REST API:** ContextID provides an API endpoint (for example, `POST /api/v1/query`) where you can submit the user’s question or command, along with their identity proof or a session token obtained from the verification step. The server will double-check the proof (if it wasn’t already done by an authorizer) and then process the query through the dual-LLM pipeline. You simply await the response.
   * **Via SDK/Library:** If you have ContextID integrated as a module in your app (say, a Node.js or Python library), you might first call something like `contextId.verify(proof)` to get a VerifiedIdentity object, then call `contextId.query(verifiedIdentity, prompt)` to get the LLM answer. Under the hood, the same steps occur.

   In either case, when the query is executed, ContextID will use the user’s verified attributes to determine what data or actions the LLM is allowed to access. For example, if the user is verified as an employee, the LLM might be allowed to retrieve that user’s files from a company database (through a tool plugin), whereas an unverified user couldn’t. All this logic can be encoded in the **system prompts or the orchestrator code** that governs the LLM’s behavior.

5. **Receive Response:** The LLM will return a response, which ContextID sends back to your application. The response can be a direct answer, or a rich result depending on your API design (for instance, it might include some metadata or usage info). At this point, you can display the answer to the user, knowing it was produced securely.

6. **Session Management (Optional):** If your use case involves multiple back-and-forth interactions (a conversation), you might not want the user to re-prove their identity on every single request. ContextID’s architecture can be extended to support session tokens. For example, after a successful proof verification, the system could issue a JWT or a short-lived session DID that is tied to the user’s identity for, say, 15 minutes. Subsequent queries could then use that token (perhaps in an `Authorization` header or cookie) instead of a full proof each time. This is similar to how OAuth works (one-time login yields a token for repeated use). The API Gateway or the ContextID backend would then accept the session token and treat it as equivalent to a proof for the duration of its validity. Implementing this is up to the integrator, but the building blocks (JWT signing, validation, etc.) can be integrated with the Lambda authorizer or backend logic.

**Integration Example Workflow:** Suppose you are building a healthcare chatbot that can retrieve a patient’s records via an LLM interface. Your patient Alice has a DID and a verifiable patient credential issued by a hospital. When Alice opens your app:

* She authenticates by selecting her DID in her wallet and responding to a proof challenge.
* Your app sends the proof to ContextID’s `/verify` endpoint or directly calls the secured `/query` endpoint with the proof.
* ContextID confirms Alice is a verified patient of that hospital (and maybe that she consented to share record X).
* Your app then calls the LLM query endpoint: “What were the results of my last blood test?” along with Alice’s verified identity context.
* ContextID’s LLM orchestrator sees the query, knows the user is Alice with patient role, and triggers a tool call to the hospital database (since the prompt asks for data) – the tool is parameterized to fetch Alice’s records only. It might do this by passing Alice’s patient ID (from the verified credential) to a database query action.
* The quarantined LLM might be used to format the database output or to interpret any free-form input in the query.
* The privileged LLM composes a friendly answer, e.g. “Your last blood test on Jan 10 showed all values in normal range.”
* The answer is returned to your app, and you show it to Alice. If an unauthorized user tried the same, they would have failed at the proof step or gotten no data from the database.

From the developer perspective, you mainly interact with high-level APIs: you ask ContextID to *verify this user* and then *get answer for this query*. ContextID takes care of the heavy security lifting behind the scenes.

## Infrastructure and Deployment

ContextID comes with an **Infrastructure-as-Code** setup (Terraform scripts) and a CI/CD pipeline to make deployment on AWS straightforward. The goal is that you can deploy a full, production-ready environment with minimal manual steps. Here’s an overview of the infrastructure and how to deploy it:

**Infrastructure Components (AWS):** The Terraform configuration (in the `infrastructure/` directory) will provision all the necessary AWS resources for ContextID. Some of the main components include:

* **Virtual Private Cloud (VPC):** A new VPC is created to house the application. It’s configured with both public and private subnets across multiple Availability Zones for high availability. The public subnets are used for internet-facing endpoints (like the load balancer or API Gateway), while private subnets are used for application servers and databases. Network access control lists (NACLs) and Security Groups are set up to restrict traffic between subnets – e.g., the database can only be accessed by the application, not directly from the internet.

* **Application Load Balancer (ALB):** If you choose to deploy via ECS (containers), an ALB is set up in a public subnet to route HTTP(S) traffic to the backend services. The ALB can be configured with OIDC authentication (for example, integrating with Cognito or any OpenID provider) to ensure only authenticated requests reach the service. Alternatively, as seen in the Terraform, an **API Gateway** can be used instead of ALB. The provided configuration leans toward API Gateway for request routing (which is serverless and includes its own endpoint). API Gateway is configured with a **Lambda Authorizer** as described, to secure each endpoint call with DID/BBS+ verification. In either case, the routing layer ensures that our backend is not directly exposed and that security checks (like auth) are enforced globally.

* **Compute: ECS Fargate and/or Lambda:** The core ContextID service (the LLM orchestrator, verification logic, etc.) can run as containerized microservices on AWS Fargate (part of Elastic Container Service), and/or as Lambda functions. The infrastructure is somewhat hybrid:

  * The Terraform config defines an **ECS cluster** and task definitions for the main service. This could be where a long-running service lives (for example, a vector database interface or a persistent orchestrator).
  * At the same time, certain components (like the API Gateway Authorizer and possibly the LLM query handler) are implemented as AWS Lambda functions (as evidenced by the Lambda authorizer integration in the API Gateway module). Lambda is used for its quick scalability and simplicity for request-based execution.

  This modular approach means you can adjust the deployment: you could run the entire ContextID backend as a set of containers, or use lambdas for stateless parts and a container for anything that needs to maintain state or hold larger models in memory. All these compute resources run in the private subnets (for ECS tasks, Fargate ensures they don’t have public IPs; for Lambda, it can be attached to the VPC for database access). IAM roles are assigned to these services to allow them to, for example, read from Secrets Manager or invoke other AWS services securely.

* **Database (Amazon RDS):** An Amazon RDS instance running PostgreSQL is deployed for persistent data storage. This can be used to store application data such as user profiles (if any), logs, or cached results. In ContextID’s case, you might not need to store much user data (since the user brings their credentials), but you could store records of queries, audit logs, or any other meta-data. The database is encrypted and resides in a private subnet. Only the application (ECS tasks or Lambdas) can connect to it, via its security group rules. The RDS credentials (username/password) are stored in AWS Secrets Manager, and not hard-coded anywhere. The application fetches them at runtime (or the ECS task is configured to automatically retrieve them and set as env variables).

* **Vector Store (Amazon OpenSearch):** If your application uses a lot of text data or documents for the LLM to reference, the infrastructure can include an Amazon OpenSearch Service cluster. OpenSearch (compatible with Elasticsearch APIs) can store vector embeddings for semantic search. ContextID can use this to implement retrieval-augmented generation: the orchestrator can vectorize incoming queries or user context and query OpenSearch for relevant passages. For example, if a user asks a question about “policy ABC,” the orchestrator could search a company policies index for “ABC” and include the relevant text in the prompt to the LLM. This OpenSearch cluster is also in a private subnet, and access is limited to the application via IAM policy or security group. (If you don’t need this feature, you can disable it in Terraform to save cost.)

* **Identity and Access Management (IAM):** Several IAM roles and policies are configured:

  * Roles for the ECS tasks and/or Lambdas to grant them least-privilege access (e.g., permission to read the secret manager for DB credentials, permission to call Comprehend or other AWS AI services if used, etc.).
  * The API Gateway (if used) gets a role to write logs to CloudWatch.
  * If using Cognito for user auth (optional), Cognito will have its own roles for allowing Cognito to send emails or verify emails, etc.
  * Importantly, an IAM Role for the **GitHub Actions CI/CD** is needed (more on this below in CI/CD setup). This role will allow GitHub to assume a role to deploy resources (instead of storing AWS keys in GitHub).

* **AWS Cognito (optional):** The architecture includes AWS Cognito User Pools as an optional component for managing user sign-up/sign-in and JWT issuance. This is somewhat independent of the DID system – you could use Cognito simply to authenticate users to your front-end or to get an initial OAuth token. In a pure DID flow, Cognito might not be necessary. However, the Terraform has it available so that if your app requires a more traditional login (email/password or social login, etc.), Cognito can be your IdP and you can map those identities to DIDs or use them in parallel. Cognito integration with API Gateway can protect endpoints by requiring a valid JWT. In ContextID, you might choose either Cognito auth, DID-based auth, or even combine them (e.g., user logs in with Cognito, but also presents a DID for certain operations). The infrastructure is flexible.

* **Secrets and Configuration:** AWS Secrets Manager is used to store secrets like database credentials, API keys (for third-party LLM services like OpenAI, if used), and any other sensitive config. The Terraform scripts show that for example the DB password is generated and stored in Secrets Manager, and not exposed. Additionally, environment variables can be defined for the application (for example, you might set an environment variable for `OPENAI_API_KEY` if using OpenAI, or for `MODEL_ENDPOINT` if using a hosted model). These can also be stored as secrets and loaded at runtime. The CI/CD pipeline can inject some config as well (like setting environment for dev vs prod).

* **Monitoring and Logging:** CloudWatch Logs are set up for API Gateway (the Terraform creates log groups for API Gateway access logs and execution logs). ECS tasks will send their logs to CloudWatch as well (by default via the awslogs driver) or to a centralized logging solution if configured. X-Ray tracing is enabled for API Gateway and can be expanded to Lambda for distributed tracing. This means you can trace a request from the gateway through the Lambda authorizer, into the backend service. CloudWatch Alarms or AWS CloudTrail (for auditing) can be added as needed to monitor unusual activities.

In summary, deploying ContextID via Terraform will set up a **full-stack AWS environment** with all the necessary pieces – networking, compute, database, search, identity services, and security configs – according to best practices for a production system.

**Deployment using Terraform and GitHub Actions (CI/CD):** The project is configured to use GitHub Actions for CI/CD, meaning you can automate testing and deployment whenever you push changes. Here’s how the deployment pipeline works and how to set it up:

* The repository likely contains a GitHub Actions workflow file (e.g., `.github/workflows/deploy.yml`) that defines the CI/CD steps. Typically, these steps include: running tests (if any), building the application (for example, building a Docker image or compiling code), and then deploying to AWS.

* **Infrastructure Deployment:** If following GitOps/Infrastructure-as-Code, the pipeline can run Terraform commands to apply the changes. For instance, upon a push to the `main` branch, the action might run `terraform init && terraform apply` in the `infrastructure/` folder. This will create or update AWS resources as defined. The Terraform state might be stored in an S3 bucket or Terraform Cloud for persistence. Make sure to configure the backend (in Terraform settings) for state storage to avoid losing state between runs.

* **Application Deployment:** If the application is containerized, the CI pipeline will build the Docker image (perhaps using a Dockerfile in the repo) and push it to Amazon Elastic Container Registry (ECR). Terraform might already define an ECR repository. After pushing the image, Terraform (or AWS ECS) will pick up the new image and deploy the tasks (for ECS) or update Lambda code if using Lambda functions (if the code is packaged as a Lambda deployment package). The pipeline might call `aws lambda update-function-code` or use Terraform to deploy the Lambda code. In some setups, Terraform might be configured to point to the latest image tag, so a separate `terraform apply` might update the service to use the new image.

* **OpenID Connect (OIDC) for CI/CD:** To avoid storing AWS credentials in GitHub, ContextID uses GitHub Actions’ OIDC federation to AWS. In your AWS account, you need to set up an IAM OIDC identity provider that trusts GitHub’s OIDC tokens, and an IAM role that GitHub Actions can assume. The Terraform scripts may include a module or resources to set this up (there are hints of that in search results, or you may set it manually). The typical setup is:

  * Create an IAM Identity Provider in AWS for `token.actions.githubusercontent.com` with a condition filtering on your repository (e.g., `repo:codemedici/ContextID`).
  * Create an IAM Role (say `GithubActionsDeployRole`) with a policy that allows it to perform needed operations (e.g., manage ECS, push to ECR, manage Lambda, CloudFormation, etc., essentially Admin or PowerUser privileges limited to your project’s resources).
  * Attach a trust policy to that role allowing the OIDC provider to assume it, with condition that the token’s sub or audience matches your repo and workflow. For example, the condition might ensure that the GitHub workflow requesting access is from `codemedici/ContextID` repository and perhaps only from the `main` branch, etc.
  * In your GitHub Actions workflow, use the official AWS Action (`aws-actions/configure-aws-credentials@v2`) to request credentials via OIDC by specifying the role to assume. This way, the CI job will get temporary AWS creds scoped to that role.

  Once OIDC is set up, your deployment pipeline can run securely with no long-lived AWS keys. If you prefer not to use OIDC, you could store an AWS access key and secret in GitHub Secrets, but that’s less secure. We strongly recommend using the OIDC method for modern best practice.

* **Configuring Environment Variables and Secrets:** As part of setup, you’ll need to configure a few things:

  * In AWS: provide any necessary variables via Parameter Store or Secrets Manager that the application expects. E.g., if using OpenAI API, store the API key in Secrets Manager and ensure the ECS task or Lambda has access. Terraform can create a secret for you (you’d input the value, of course). The application reads configuration like `OPENAI_API_KEY`, `MODEL_PROVIDER`, `ISSUER_DID` (if verifying credentials only from a specific issuer), etc., from these sources.
  * In GitHub: add repository secrets for any values the CI/CD pipeline needs that cannot be baked into the repo. For example, if using Terraform Cloud, you’d need an API token (but likely not, since we deploy directly to AWS). If some parts of deployment need passwords or keys, put them in GitHub Secrets and reference in the workflow. With OIDC, you might not need any AWS secrets here. But you might include a secret for something like a Docker Hub token if pulling base images, etc., if required.

* **Running the Deployment:** With everything configured, triggering a deployment is usually as simple as **pushing to the main branch** or creating a tagged release (depending on how the workflow is set up). The GitHub Action will start, run tests, build artifacts, assume the AWS role via OIDC, apply Terraform, build and push containers, and update the infrastructure. On success, your ContextID stack on AWS will be up-to-date. On failure, you can check the Actions logs for debugging.

* **Terraform State & Backend:** If the Terraform backend is local (default), the state file will be updated in the runner and lost after the run. You should configure a remote state (S3 + DynamoDB lock or Terraform Cloud workspace) for persistent storage, especially if multiple people or automation are deploying. We recommend setting that up before running `terraform apply`. You can integrate this in the pipeline by configuring environment variables or backend config in Terraform.

* **Post-Deployment:** After deployment, you will have:

  * A REST API endpoint (either an ALB DNS or API Gateway URL) for your ContextID service.
  * The Lambdas and ECS tasks running your application logic.
  * All the supporting services (RDS, etc.) running and configured.
  * You can then start sending requests (with proper auth) to the API to test the system. Always test in a development environment first. Check CloudWatch logs for the Lambda authorizer and the LLM handler to ensure that verification and queries are working as expected.

Deploying a full system like this can be complex, but the provided Terraform scripts and CI/CD workflow aim to automate as much as possible. Make sure you review the Terraform variables (there might be a `terraform.tfvars.example` or default values) – you may need to provide values like AWS region, allowed IPs, instance sizes, etc. If you encounter issues, common ones include AWS permissions (ensure the CI role has the right policies) and service quotas (the default VPC or subnet counts, for example, if you already have many, or instance type availability in your region). Reading Terraform and plan outputs will guide you.

Once set up, you will have a robust infrastructure that you can reuse for other projects as well – it’s a generic template for secure LLM applications, with ContextID as the core.

## API Usage Examples

To illustrate how a developer can call the ContextID service, let’s walk through some sample API requests. We’ll assume the ContextID system is deployed and running at an endpoint (for example, `https://api.example.com` or a given API Gateway URL). These examples demonstrate verifying a DID and then performing a secure LLM query using that identity proof.

### 1. Verify Identity Example

If using a two-step approach (separating verification and query), you might have an endpoint like `POST /verify`. A client (e.g., your front-end or a curl command) would call it as follows:

```bash
curl -X POST "https://api.example.com/verify" \
  -H "Content-Type: application/json" \
  -d '{
        "did": "did:example:alice12345",
        "proof": {
            "type": "BbsBlsSignatureProof2020",
            "created": "2025-08-01T12:00:00Z",
            "proofValue": "rhfiuQ96...Nb8=", 
            "proofPurpose": "authentication",
            "verificationMethod": "did:example:alice12345#key-1",
            "nonce": "SGVsbG8gQ29udGV4dElE" 
        }
     }'
```

In this hypothetical payload:

* `"did"` is the user’s DID.
* `"proof"` contains the BBS+ proof in a JSON form (the exact structure may vary depending on the VC format; it could also be a compact string or JWT). It includes things like the proof type (BbsBlsSignatureProof2020), creation time, the proof value (signature), the verification method (which key in the DID Doc was used), and a nonce.

**Response:** If the proof is valid, the API might return a JSON confirming verification. For example:

```json
{
  "verified": true,
  "did": "did:example:alice12345",
  "attributes": {
    "role": "premium_user",
    "member_since": "2023-01-01"
  },
  "exp": 1690918400
}
```

This indicates the DID is verified. The service might also echo back the disclosed attributes (here, perhaps the credential proved Alice is a "premium\_user" and her membership date). It could also include an `exp` (expiry) to suggest how long this verification is valid (if using a session token). If verification fails, you’d get a 401 status or a response like `{ "verified": false, "error": "Invalid proof" }`.

### 2. Query LLM with Proof (Single-step example)

In many cases, you might skip a separate verify call and directly call the LLM query endpoint with the proof attached. The API Gateway authorizer will handle the verification before the request reaches the handler. Here’s an example of a single-step query:

```bash
curl -X POST "https://api.example.com/query" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <proof-token-or-JWT>" \
  -d '{
        "did": "did:example:alice12345",
        "prompt": "What is the balance of my savings account?",
        "context": "banking"
      }'
```

In this scenario:

* The proof (which could be large) might be passed in the Authorization header as a Bearer token (this could be a JWT that encapsulates the proof or a reference to a proof stored server-side). Alternatively, you could include it in the body as we did before. Using the header and treating it like an auth token is convenient with API Gateway’s custom authorizer.
* The body includes the user’s DID (possibly redundant if it’s in the proof, but sometimes useful to specify) and the actual `prompt` we want the LLM to answer. We also include a `"context": "banking"` field – imagine our service supports multiple domains of questioning, here we hint it’s about banking, so the system might use that to route the request or fetch relevant data. (This field is optional and just for demonstration.)

**What happens:**

* API Gateway receives this request, triggers the Lambda authorizer with the `Authorization` header. The authorizer validates the token/proof. If valid, it might return a policy allowing the `query` endpoint and pass along the user’s DID and attributes as context.
* The `/query` Lambda (or ECS service) then runs. It sees the user is verified and maybe gets info like `role: premium_user` from the context. It uses the dual LLM orchestrator to answer the question. Perhaps it knows the DID corresponds to an internal user ID and uses a database tool to lookup Alice’s accounts. It finds her savings account balance (say \$5,000) and then the LLM formulates a nice answer.
* The response might be something like:

```json
{
  "answer": "Your savings account balance is $5,000.",
  "source": "internal-banking-db",
  "timestamp": "2025-08-01T12:05:30Z"
}
```

Where `"answer"` is the LLM’s answer. We include `"source"` and timestamp for transparency (for example, the system might tell the user how it got the info). The exact format is up to the implementation; it could also just be \`{"answer": "..."} for simplicity.

If the proof was invalid or missing, the request would never reach the LLM function – the authorizer would have rejected it. The client would get an HTTP 401 Unauthorized error.

### 3. Using a Session Token (Optional)

If the system issued a session token after verification (say a JWT with a short lifetime), subsequent calls could use that instead of the full proof every time. For example:

```bash
# First, login/verify to get a token
curl -X POST "https://api.example.com/login" -d '{ "did": "...", "proof": { ... } }'

# Response contains a token
{ "token": "<JWT-token-here>", "expires_in": 900 }

# Subsequent query using the token
curl -H "Authorization: Bearer <JWT-token-here>" -d '{ "prompt": "..." }' https://api.example.com/query
```

The Lambda authorizer in this mode would recognize the JWT, verify it (check signature and expiry) instead of a BBS+ proof each time, and then allow access. This is more of a standard web app pattern layered on top of ContextID’s DID verification.

---

These examples show a REST-style integration, but you could also integrate in other ways. For instance, if you embed ContextID’s logic in your server application, you might simply call a function `answer = contextid.handleQuery(userDid, proof, prompt)` and get back the answer (this function internally does what the service above would do). The underlying concepts remain: verify first, then answer with dual-LLM safety.

When implementing, make sure to handle errors gracefully:

* Expired or invalid proofs -> return an auth error.
* If the LLM cannot answer or a tool fails (e.g., database down) -> return a relevant error or message.
* If the user’s request is not allowed (maybe they ask for data they aren’t entitled to even though they are verified) -> the system might return a polite refusal (the LLM could be prompted to say “I’m sorry, I cannot assist with that request” or the server returns a 403 Forbidden).

By following these integration patterns, you can incorporate advanced identity-aware AI features into your app with minimal effort, offloading the heavy security concerns to ContextID.

## Setup Instructions

Setting up ContextID for development or deployment requires a few preparatory steps. This section covers prerequisites, configuration of environment variables and secrets, AWS IAM setup for CI/CD, and how to run the system (both via CI/CD pipeline and manually for testing).

**Prerequisites:**

* **AWS Account:** You will need access to an AWS account where you have permissions to create resources (VPCs, EC2, RDS, Lambda, etc.). If you are testing locally only, you can skip AWS, but to use the full infrastructure as intended, AWS is required.
* **Terraform:** Install Terraform (v1.3 or newer is recommended). The infrastructure provisioning is done through Terraform scripts. Review the Terraform files in the `infrastructure` directory to familiarize yourself with required variables (region, instance sizes, etc.). Ensure you have AWS credentials set up locally if you plan to run Terraform manually.
* **AWS CLI:** (Optional but useful) Install the AWS CLI to interact with AWS services and verify resources. It’s also used if you run any deployment scripts manually or want to retrieve outputs.
* **Docker:** If you plan to build or run containers locally (or build images for ECS), have Docker installed. The CI pipeline will also use Docker to build images.
* **Programming Environment:** Depending on the language of ContextID’s implementation (for example, if the backend is in Node.js or Python), ensure you have the appropriate runtime and build tools. For instance, if it’s Node.js, install Node.js 18+ and npm/yarn; if Python, install Python 3.9+ and pip. (Check the repository for language specifics. The presence of Lambdas suggests possibly Python or Node; ensure you have what’s needed to run the code.)

**Project Configuration:**

* **Environment Variables (.env):** ContextID may use environment variables for configuration. Typically, there may be a `.env.example` file provided. Key variables might include:

  * `OPENAI_API_KEY` or `HUGGINGFACE_API_TOKEN` if using external LLM APIs.
  * `MODEL_PROVIDER` or `MODEL_NAME` if you can select which LLM to use.
  * `DB_SECRET_NAME` or `DB_CONN_STR` if local dev (in AWS, it fetches from Secrets Manager).
  * `ISSUER_DID` or trusted issuer list if only certain credential issuers are accepted.
  * `CHALLENGE_SECRET` if using an HMAC-based challenge for proofs (just a possibility).

  For local development, you’d create a `.env` file with the necessary keys. In AWS, these values are either in Secrets Manager or provided via Lambda environment config. Make sure to set them accordingly. For example, you might need to put your OpenAI key in Secrets Manager under a name that the Lambda expects, or configure an API Gateway parameter.

* **AWS IAM OIDC Setup (CI/CD):** As discussed, to allow GitHub Actions to deploy to AWS, set up OIDC:

  1. In AWS IAM, create a new OIDC Identity Provider for GitHub:

     * Provider URL: `https://token.actions.githubusercontent.com`
     * Audience: `sts.amazonaws.com`
  2. Create a Role (e.g., `ContextID-CICD-DeployRole`) with trust policy referencing the OIDC provider. The policy should allow the GitHub repo to assume it. For example:

     ```json
     {
       "Effect": "Allow",
       "Principal": { "Federated": "arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:oidc-provider/token.actions.githubusercontent.com" },
       "Action": "sts:AssumeRole",
       "Condition": {
         "StringEquals": {
           "token.actions.githubusercontent.com:sub": "repo:codemedici/ContextID:ref:refs/heads/main"
         }
       }
     }
     ```

     This ensures only the ContextID repo on main branch can assume the role. Adjust if you want to allow other branches or a fork (e.g., for pull request previews you might include `:pull_request` in the ref conditions).
  3. Attach a permissions policy to this role that allows it to create/update all the resources in your Terraform. Simplest is AdministratorAccess (for a quick start), but for production you’d tailor a policy to only allow specific actions (EC2, Lambda, IAM, RDS, etc.). At minimum, it needs rights to manage: VPCs, EC2 security groups, IAM roles/policies, CloudFormation (if Terraform uses it), RDS, Lambda, ECS, API Gateway, OpenSearch, Cognito – essentially the components described in the infrastructure.
  4. Note the Role ARN. In your GitHub Actions workflow file, configure the AWS credentials action to use that role. For example:

     ```yaml
     - name: Configure AWS Credentials
       uses: aws-actions/configure-aws-credentials@v2
       with:
         role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/ContextID-CICD-DeployRole
         aws-region: us-east-1
     ```

     No secrets needed – GitHub will fetch a token and assume the role at runtime.

* **GitHub Secrets for CI:** If any secrets are needed in the CI pipeline (like if you push Docker images to Docker Hub or want to notify a Slack webhook, etc.), store them in GitHub Secrets and reference in the workflow. For example, if not using ECR, and you push to Docker Hub, you’d have `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets. By default, if using AWS ECR, the AWS role can push, so no separate secret needed.

* **Running Locally (optional):** If you want to run the LLM service locally for development (without all AWS setup):

  * You might use a local DID resolver or mock for verification, and skip BBS+ (or include a library).
  * Provide dummy secrets or use local services (e.g., run a local Postgres and set `DB_CONN_STR`).
  * You could run a local OpenSearch in Docker if needed.
  * Then run the backend application (e.g., `npm start` or `python app.py`). This can be helpful to iterate on prompt logic or verification logic quickly. The README or docs might have a section for local dev; if not, you can create a minimal environment that simulates what AWS would provide.
  * Always be careful to not hardcode any secrets or keys in code – rely on env variables so that switching to AWS Secrets Manager is seamless.

* **CI/CD Pipeline Usage:** With IAM and secrets configured, you don’t manually run deploy commands. Simply pushing code triggers the pipeline. However, for initial setup, you might want to run `terraform plan` manually to see what will be created, or even apply it manually once to bootstrap (especially if state is remote, first run might be easier locally to set up state storage). After that, CI can take over. The pipeline also likely runs tests. Ensure any tests (unit or integration) pass before deploying. For example, if the repository includes unit tests for the verification functions or prompt templates, the workflow will run them. Run `npm test` or `pytest` locally to verify.

* **AWS Resource Bootstrapping:** Some AWS services need one-time setup:

  * If using Cognito, you might need to set domain names or callback URLs manually, or Terraform might handle it. Check if you must verify an email domain for Cognito.
  * If using domain names for API Gateway or ALB (custom domain with SSL), you’d need to have a Route53 domain and certificate (AWS Certificate Manager). Terraform can request a certificate but DNS validation needs to happen. Read the docs/terraform comments if any for this.
  * S3 bucket for static front-end: Terraform might create it. If you plan to host a frontend, upload your build files to that S3, and invalidate CloudFront cache if applicable. For now, it might just be a placeholder bucket.

* **Secrets Rotation:** For long-term security, remember to rotate secrets periodically (DB passwords, etc.). Using Secrets Manager makes it easier – you can enable rotation for RDS credentials and update the app secrets accordingly.

Once all setup steps are done, you should have a fully working instance of ContextID. Test a full flow:

* Deploy to a dev environment.
* Create a test DID and credential (or use a demo one).
* Use a tool or script to generate a BBS+ proof from that credential (there are libraries in JS/TS and Rust for this, e.g., `@mattrglobal/bbs-signatures`).
* Call the API endpoints as in the examples to ensure verification passes and the LLM responds correctly.
* Try an unauthorized scenario to ensure it correctly blocks (for instance, modify the proof or use someone else’s DID to see it fail).
* Try a prompt injection attempt (like put `##IGNORE## all prior instructions` in the prompt) and see that the system doesn’t fall for it – the response should either ignore the malicious instruction or return some safe error.

Congratulations, you now have a zero-trust, identity-aware LLM service running!

## Contribution Guidelines

Contributions to ContextID are welcome and encouraged! As an open-source project, we rely on the community to help improve the code, add features, and fix bugs. Below are some guidelines to make the contribution process smooth for everyone:

* **Project Setup for Contributors:** Follow the setup instructions above to get a working development environment. If you plan to contribute code, it’s best to fork the repository on GitHub, clone your fork, and perhaps create a separate AWS dev setup (you can use local Docker or a separate AWS test account to avoid impacting production resources).

* **Issue Tracker:** If you find a bug or have an idea for a new feature, please check the GitHub Issues first to see if it’s already reported. If not, open a new issue. Provide as much detail as possible: steps to reproduce the bug, or use cases and examples for the feature request. Label the issue appropriately (bug, enhancement, question, etc., if labels are available).

* **Discussion:** For larger feature ideas or design changes, it might be good to start a discussion (GitHub Discussions or an issue) to get feedback from maintainers and other contributors before investing a lot of time in coding. This can save effort and ensure your idea aligns with project goals.

* **Pull Requests:** We use the Fork & Pull model. That means you should fork the repository, create a new git branch for your change (descriptive branch names like `fix/prompt-timeout-bug` or `feature/add-logging`), commit your changes with clear messages, and push to your fork. Then open a Pull Request (PR) against the `main` branch of the main repository. In the PR description:

  * Reference any issue it addresses (e.g., “Closes #12”).
  * Describe what you changed and why.
  * Add any relevant screenshots or logs if it’s a UI or output change.
  * Ensure that your code follows the existing style. If there is a linter or formatter, run it (the CI may also run checks).
  * Write tests for your changes if applicable. For example, if you’re modifying the DID verification logic, include a test for the new scenario (maybe in a `tests/` directory). Ensuring tests pass will speed up the review.

* **Coding Style:** The project tries to maintain clean and readable code. Use meaningful variable and function names. Add comments where the purpose of code isn’t obvious. If the project has a style guide or uses a tool like ESLint/Prettier (for JS/TS) or Black/Flake8 (for Python), make sure to run those. The CI pipeline likely checks formatting and basic static analysis.

* **Commit Messages:** Write clear commit messages. Start with a short summary (max 50 characters), followed by an optional body that describes what and why in more detail. If your commit fixes an issue, include the issue number. Example:

  ```
  Fix DID proof verification timing bug

  The nonce comparison was using milliseconds instead of seconds, causing some proofs to be mistakenly marked expired. Switched to seconds to fix #34.
  ```

  You don’t need to squash commits yourself – maintainers might squash-and-merge, but keeping commits logically separated is fine.

* **Testing:** Before submitting, run the test suite (if one exists) to ensure nothing broke. If you added a feature, consider adding a test for it. Also, manual testing with sample requests (like those in the README) is highly recommended to ensure your dev environment still works end-to-end.

* **Documentation:** If you add or change a feature, update the documentation accordingly. This could mean updating this README, or any other docs in the `docs/` folder or code comments. If adding a new API endpoint, document its request/response format. If your change affects deployment, update the deployment instructions or Terraform comments as needed.

* **CI Pipeline:** The GitHub Actions will run for your pull requests (especially if you open a PR from a fork, ensure the Actions are enabled for forked PRs in the repo settings, or maintainers can run them). Make sure your PR passes all checks (lint, build, test, etc.). A PR that fails CI likely won’t be reviewed until it’s fixed.

* **Code Review:** Be open to feedback. Maintainers might request changes or ask questions. This is a normal part of the process to maintain quality. Respond to reviews, make the requested changes, and push updates which will automatically update the PR. Once approved, a maintainer will merge your PR.

* **Contributor License Agreement (CLA):** All contributions are assumed to be made under the same license (Apache-2.0) that the project is released under. By submitting a pull request, you assert that you have the right to contribute the code (it’s your own work or you have rights to it) and you agree to license it under Apache-2.0. If the project requires signing a CLA or DCO (Developer Certificate of Origin), please follow those instructions (check CONTRIBUTING.md or CLA.md if present). Usually, simply including a `Signed-off-by` in your commit message (for DCO) might be needed.

* **Community Conduct:** Please be respectful and constructive in communication. We want a welcoming environment for collaborators. Follow the [Code of Conduct](CODE_OF_CONDUCT.md) (if one is provided, or generally the standard Contributor Covenant) when interacting in issues and PRs.

By contributing to ContextID, you’re helping build a more secure and trustworthy AI ecosystem. Whether it’s a small typo fix or a major new feature, we appreciate your effort!

## License and Governance

**License:** This project is licensed under the Apache License, Version 2.0 (Apache-2.0). This means you are free to use, modify, and distribute this software in your own projects, whether open-source or proprietary, as long as you comply with the license (which mainly requires giving credit to the authors and including the license notice in any distributions of the code). Apache-2.0 is a permissive license, allowing commercial use, distribution, and private use. There is no warranty for the software. For the full license text, see the `LICENSE` file in the repository. By contributing to this project, you agree that your contributions will be licensed under the same Apache-2.0 license.

**Governance:** ContextID is an open-source project started by the maintainers at CodeMedici (and any affiliated contributors). The project operates in a transparent, community-driven manner. There is no formal governance board or steering committee at this stage; decisions are made by the core maintainers, but we heavily value input from the community:

* **Maintainers:** The current maintainers are the people with commit access to the repository (initially the creators of the project). They review pull requests, manage releases, and set the roadmap.
* **Community Involvement:** We invite the community to participate through GitHub Issues, pull requests, and discussions. Significant decisions (like major architectural changes, adding a new dependency, etc.) will typically be discussed openly in issues or discussion threads. We aim for consensus where possible. If disagreements arise, maintainers will make a decision guided by what’s best for the project’s goals (security, reliability, usability).
* **Release Process:** We plan to tag releases (using semantic versioning once the project stabilizes). Maintainers will handle creating new releases. If you need a certain fix that’s on the main branch but not in a formal release yet, you can build from source or ask maintainers if a new tagged version can be published.
* **Contribution Recognition:** All contributors are listed in the GitHub contributor’s list. We may also acknowledge significant contributions in the README or release notes. Since it’s Apache-2.0, there’s no contributor license transfer; you retain copyright to your contributions, but grant the project license to use them.
* **Future Governance:** As the project grows, we may adopt a more formal governance model (such as a core team, voting on proposals via a Request for Comments process, etc.), especially if a wider community or companies start depending on ContextID. Any changes to governance will be documented in the repository (e.g., in a GOVERNANCE.md).

Our goal is to foster an inclusive and active open-source community around ContextID. The combination of **Apache-2.0 licensing** and open governance is meant to ensure the project remains free to use and can evolve with input from many stakeholders. We encourage you to use ContextID in your own projects, give feedback, and contribute back improvements!

---

*Thank you for using and contributing to ContextID.* By leveraging decentralized identities and robust AI architecture, we can make the next generation of applications both smart and secure. We’re excited to see what you build with ContextID. If you have any questions or need support, feel free to open an issue or join our community channels. Happy coding!
