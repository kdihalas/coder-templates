---
name: Develop in Linux on a ScaleWay Instance
description: Get started with Linux development on a ScaleWay Instance.
tags: [cloud, scaleway]
---


## Authentication

The Scaleway authentication is based on an access key, and a secret key. Since secret keys are only revealed one time (when it is first created) you might need to create a new one in the section "API Keys" of the Scaleway console. Click on the "Generate new API key" button to create them. Giving it a friendly-name is recommended.

The Scaleway provider offers three ways of providing these credentials. The following methods are supported, in this priority order:

Environment variables
Static credentials
Shared configuration file
Environment variables
You can provide your credentials via the `SCW_ACCESS_KEY`, `SCW_SECRET_KEY `environment variables.