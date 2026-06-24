---
date: 2026-06-24T10:19:56+10:00
type: blurb
tags:
  - glazier
  - hcl
---

Welp. I've convinced myself that Glazier needs Terraform-style variable declaration blocks to validate `--var` flags. I'm doing it and I will not be stopped. I'm thinking something as simple as the following `session` block-adjecent top-level spec:
```hcl
variable "name" {
  description = optional(string)
  type        = required(string | bool | number)
  default     = optional(type)
}
```
Time to do what I do best: make things more complicated than they have any right to be.
