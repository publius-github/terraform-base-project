# terraform-base-project
This repo contain base TF structure to start work with.


## requirenments
- docker


## usage
```bash
# for env apply
make plan module="envs" env="nonprod"
make apply module="envs" env="nonprod"

# for general apply
make plan module="general" env="nonprod"
make apply module="general" env="nonprod"

# for infra apply
make plan module="infra" env="nonprod"
make apply module="infra" env="nonprod"

# for format TF code, and create TF readme
make format
```


## structure

```
.
├── files                    # contains all kind of files
│   └── scripts
└── terraform
    ├── envs                 # contains TF code that uniq per env
    │   ├── main
    │   ├── nonprod
    │   └── prod
    ├── general              # contains TF code that repeats per env
    ├── infra                # contains TF code for core infra such networks
    └── modules              # contains custom TF modules
        └── network            
```
