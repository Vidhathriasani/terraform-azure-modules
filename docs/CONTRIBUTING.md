# Contributing

## Development Setup

1. Install Terraform >= 1.5.0
2. Install TFLint
3. Install Go >= 1.21 (for Terratest)

## Module Guidelines

### Structure

Each module follows a consistent structure:
```
modules/<name>/
├── main.tf          # Resources
├── variables.tf     # Input variables with descriptions
├── outputs.tf       # Output values
└── README.md        # Auto-generated documentation
```

### Conventions

- Use `this` as the primary resource name
- Data sources for existing resources (don't create resource groups)
- Always include `tags` variable with module identification
- Mark sensitive outputs with `sensitive = true`
- Use `lookup()` with defaults for optional map values
- Include validation blocks for constrained inputs

### Testing

```bash
cd tests
go test -v -timeout 30m
```

### Formatting

```bash
terraform fmt -recursive
```

## Pull Request Process

1. Ensure `terraform validate` passes for all modules
2. Run `terraform fmt -check -recursive`
3. Update examples if module interfaces change
4. Add tests for new modules
