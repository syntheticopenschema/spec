# Contributing to Synthetic Open Schema

Welcome to the Synthetic Open Schema specification, stewarded by Ideatives Inc.! We appreciate your interest in contributing to this open-source project. This repository focuses on defining and evolving the schema used for synthetic monitoring checks.

## Ways to Contribute

You can contribute to the Synthetic Open Schema project in several valuable ways:

1. **Reporting Issues**: Help identify bugs, request clarifications, or suggest improvements to the schema by [creating an issue](https://github.com/syntheticopenschema/spec/issues/new).

2. **Submitting Pull Requests**: Contribute directly by proposing changes to the schema, adding new features, or refining existing definitions. Follow the guidelines below when submitting your pull requests.

3. **Documentation**: Improve existing documentation, provide examples, or clarify usage instructions related to the schema definitions.

4. **Testing**: Validate the schema in different scenarios to ensure robustness and compatibility with various monitoring setups.

5. **Feedback**: Share your experiences using the Synthetic Open Schema, provide insights into usability, or participate in discussions about future enhancements.

## Getting Started

### Setting Up Your Environment

To contribute to the Synthetic Open Schema project, you'll need:

- **Git**: Version control system.
- **YAML Knowledge**: Familiarity with YAML syntax and best practices.
- **Text Editor**: Choose one that you're comfortable with for editing code and documentation.

### Fork and Clone the Repository

1. Fork the repository on GitHub.
2. Clone your forked repository locally:

   ```bash
   git clone https://github.com/your-username/synthetic-open-schema.git
   cd synthetic-open-schema
   ```

### Setup your python environment

Dependencies are managed using [Poetry](https://python-poetry.org/). To install Poetry, follow the instructions [here](https://python-poetry.org/docs/#installation).

Common tasks are managed using [Just](https://just.systems/). To install Just, follow the instructions [here](https://just.systems/man/en/chapter_2.html)

1. Install dependencies

```bash
just install
```

2. Run tests
```bash
just test
```

Note: Test are running using [pytest-watch](https://github.com/joeyespo/pytest-watch), which will keep listening for changes and re-execute the testsuite as soon as change is detected, encouraging for a dynamic test driven development.

### Making Changes

1. Create a new branch for your changes:

   ```bash
   git checkout -b my-feature-branch
   ```

2. Make your changes to the schema definitions or documentation.

3. Validate your changes against the existing schema (if applicable).

4. Commit your changes:

   ```bash
   git add .
   git commit -m "Add or update schema definition for XYZ"
   ```

5. Push your changes to your forked repository:

   ```bash
   git push origin my-feature-branch
   ```

### Submitting Pull Requests

1. Go to your forked repository on GitHub and create a pull request.
2. Provide a clear description of your changes and why they are necessary or beneficial.
3. Ensure your pull request adheres to the [coding conventions](#coding-conventions) and includes any relevant documentation updates.

## Coding Conventions

- Follow YAML syntax conventions and adhere to the existing structure and naming conventions in the schema files.
- Use clear and descriptive commit messages that explain the purpose of your changes.

## Code of Conduct

Please review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) when participating in this project.

## Questions and Feedback

If you have any questions, feedback, or encounter issues while contributing, please open a discussion in [GitHub Issues](https://github.com/syntheticopenschema/spec/issues).

Thank you for contributing to the Synthetic Open Schema. Your contributions help improve the schema's usability and benefit the entire community of developers and monitoring enthusiasts!
