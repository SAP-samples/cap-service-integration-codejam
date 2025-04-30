# Prerequisites

These prerequisites are essential to a successful CodeJam. As an attendee, please ensure that you have worked through all of them and set things up before the day of the CodeJam event itself.

## Working environment

While there are many ways to work with the SAP Cloud Application Programming Model, with a wide choice of editors and command lines, we will use a primary environment, but also support an alternative. You must decide whether you want to use the primary environment or the alternative, and make sure you have the corresponding prerequisites set up accordingly.

The primary environment is a Dev Space in the SAP Business Application Studio. The alternative environment is VS Code with a dev container.

> The words "primary" and "alternative" are not meant to convey any superiority of one over the other.

Once you've decided on your environment, follow the corresponding subsection below to make sure you have what you need, and then continue working through any other prerequisites in this document.

### Primary environment: An SAP Business Application Studio Dev Space

If you opt for the primary environment, you'll be working in a Dev Space in the SAP Business Application Studio. Therefore you'll need a subscription to the SAP Business Application Studio in an account on the SAP Business Technology Platform (SAP BTP). You may find this tutorial helpful: [Get a Free Account on SAP BTP Trial](https://developers.sap.com/tutorials/hcp-create-trial-account.html).

👉 Check you have a subscription to access the SAP Business Application Studio.

### Alternative environment: VS Code with a dev container

If you opt for the alternative environment, you'll need [Microsoft VS Code](https://code.visualstudio.com/) and [Docker Desktop](https://www.docker.com/products/docker-desktop/).

> Docker Desktop is free to use for personal use. However, you may wish to use a different container runtime such as [Podman](https://podman.io/). If you do, you are on your own (as we assume you're confident enough to take this path) but please note the warning in Exercise 01, at the end of the [Establishing the container](exercises/01-set-up-workspace#establishing-the-container) if you're working with different architectures.

You'll also need [git](https://git-scm.com/) to be able to clone this repository to your local filesystem to get started.

👉 Ensure you have VS Code, Docker Desktop and git available on your machine and that you have administrative access.

👉 Once you have VS Code, check that you have the Dev Containers extension - you can read about this and how to install it in this [Dev Containers tutorial](https://code.visualstudio.com/docs/devcontainers/tutorial).

## Other prerequisites

You'll also need SAP BTP account details to be able to log into the [SAP Business Accelerator Hub](https://api.sap.com/); this is because downloading API specifications from that website, which you'll be doing early on in the CodeJam, requires you to be authenticated.

👉 Check this by heading over to the [SAP Business Accelerator Hub](https://api.sap.com) and ensuring that you can log in.

We recommend Google Chrome as the browser if you are using the SAP Business Application Studio ([more browsers are of course supported](https://help.sap.com/docs/SAP%20Business%20Application%20Studio/9d1db9835307451daa8c930fbd9ab264/8f46c6e6f86641cc900871c903761fd4.html?locale=en-US&q=sap%20business%20application%20studio%20chrome#availability)) specifically because you'll be encouraged to use a particular extension to make things more comfortable during the course of the CodeJam.

## Knowledge and experience

From a knowledge and experience perspective, the following is useful but not essential:

* Some general experience of CAP
* In particular, some familiarity with CDS
* Some familiarity with JavaScript syntax
