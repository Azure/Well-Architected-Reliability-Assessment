# Contributing to Well-Architected Reliability Assessment (WARA)

Firstly, thank you for taking the time to contribute!

The Well-Architected Reliability Assessment (WARA) tool is designed to help customers assess the reliability of their Azure workloads based on the Well-Architected Framework. By contributing, you can help our community get the best out of this tool.

We actively encourage community contributions. We realize the unique and diverse requirements of our customers can help drive a better outcome for everyone.

The following is a set of general guidelines for contributing to this project.

## Before You Start

To ensure your contribution aligns with the goals and standards of WARA, please:
* Review the [WARA conceptual architecture and design principles](/README.md) to understand the project's direction and core values.
* Familiarize yourself with existing functionality and documentation.
* Review our [PowerShell best practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.5&utm_source=chatgpt.com) and any naming conventions or templates(/src/modules/wara/) used in [scripts, modules, classes and tests](/src/).

## How Can I Contribute?

As an open-source project, WARA works best when it reflects the needs of our community of consumers. As such, we welcome contributions however big or small. All we ask is that you follow some simple guidelines, including participating according to our [Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

### Reporting Bugs

Bugs are tracked as [GitHub Issues](https://github.com/Azure/Well-Architected-Reliability-Assessment/issues).

Before reporting a bug, please check the existing issues to see if it has already been reported. If you find an existing issue for your bug, please add any additional information you have or give it a 👍.

When creating a new bug report:
*   Use a clear and descriptive title.
*   Describe the steps to reproduce the bug.
*   Explain the behavior you observed and what you expected instead.
*   Include details about your environment (e.g., PowerShell version, Az module version and OS).
*   Provide evidence (e.g., screenshots, error messages, logs).
*   Ensure you fill out the template with as much information as possible.
*   Optionally, submit a Pull Request to resolve submitted issue 🔧.

### Feature Requests

We understand that WARA is going to always be a work in progress, and that customers will need and want to request new features. This is where you can really make a difference to how the solution is shaped for our community.

Feature requests are also tracked as [GitHub Issues](https://github.com/Azure/Well-Architected-Reliability-Assessment/issues).

If you have an idea you would like to be considered for inclusion, please use the following process:
1.  Familiarize yourself with the project's goals and existing functionality.
2.  Check the existing issues to see if a similar feature has already been requested. If so, add your thoughts or 👍 to the existing issue.
3.  Create a new issue using the "Feature Request" template.
4.  Clearly describe the feature and the problem it solves.
5.  Explain why you feel this will benefit the community (e.g., provide a business case or scenario). This is required for all significant changes, including bug fixes that alter core behavior.
6.  Optionally, submit your requested feature via a Pull Request 🔧.

### Report a Security Vulnerability

Please see our [Security Policy](https://github.com/Azure/Well-Architected-Reliability-Assessment/blob/main/SECURITY.md) for more information on how to report security vulnerabilities.

### Submitting Pull Requests

If you'd like to contribute code, documentation, or tests, please follow these steps:

1.  **Fork the repository:** Create your own fork of the `Azure/Well-Architected-Reliability-Assessment` repository.
2.  **Clone your fork:** Clone your fork locally (`git clone https://github.com/YOUR_USERNAME/Well-Architected-Reliability-Assessment.git`).
3.  **Create a branch:** Create a new branch for your changes.
### Example

```
feat: add new authentication experience
^--^  ^------------^
|     |
|     +-> Summary in present tense.
|
+-------> Type: chore, docs, feat, fix, refactor, style, or test.
```

More Examples:

- `feat`: (new feature for the user, not a new feature for build script)
- `fix`: (bug fix for the user, not a fix to a build script)
- `docs`: (changes to the documentation)
- `style`: (formatting, missing semi colons, etc; no production code change)
- `refactor`: (refactoring production code, eg. renaming a variable)
- `test`: (adding missing tests, refactoring tests; no production code change)
- `chore`: (updating grunt tasks etc; no production code change)
4.  **Make your changes:** Implement your feature or bug fix.
    *   Follow [PowerShell best practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.5&utm_source=chatgpt.com).
    *   Use existing scripts, modules, and tests as templates for style and structure.
    *   Update or add relevant documentation in the `docs/` folder.
    *   Add or update Pester tests in the `src/tests/` folder for any code changes. Ensure tests pass locally.
5.  **Commit your changes:** Commit your changes with clear and concise commit messages (`git commit -m "feat: Add new error handling for X cmdlet"`).
6.  **Push to your fork:** Push your changes to your fork (`git push origin feature/your-feature-name`).
7.  **Open a Pull Request:** Go to the original `Azure/Well-Architected-Reliability-Assessment` repository and open a Pull Request from your branch to the `main` branch.
    *   Fill out the Pull Request template thoroughly.
    *   Link any relevant issues (e.g., `Closes #123`).
    *   Ensure all automated checks pass.
    *   Your contribution will be reviewed by maintainers for consistency, alignment with project goals, and community benefit. Feedback may be provided before merging.

Maintainers will review your Pull Request and provide feedback or merge it. It is worth reviewing the general developer workflow for contribution [which is documented in GitHub](https://docs.github.com/en/get-started/quickstart/contributing-to-projects).

## Scope of Contributions

We welcome contributions in the following areas:
* Bug fixes
* New features aligned project goals
* Documentation improvements
* Test coverage and quality improvements

If you are unsure whether your idea fits the project, please open an issue for discussion first. Contributions that do not align with the project's goals or design principles may not be accepted.

## Additional Resources

* [WARA Main Documentation](/README.md)
* [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)

## Code of Conduct

This project adheres to the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). By participating, you are expected to uphold this code. Please report unacceptable behavior to [opencode@microsoft.com](mailto:opencode@microsoft.com).
