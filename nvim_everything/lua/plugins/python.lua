return {
  -- Configure Python LSP with basedpyright
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          -- Enable the LSP
          enabled = true,
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic", -- Enable type checking for linting
                autoImportCompletions = true,
                useLibraryCodeForTypes = true,
                diagnosticSeverityOverrides = {
                  -- Show useful errors/warnings
                  reportUnusedVariable = "warning",
                  reportUnusedImport = "warning",
                  reportMissingImports = "error",
                  reportUndefinedVariable = "error",

                  -- Disable false positives (common in dynamic Python code)
                  reportAttributeAccessIssue = "none", -- "object has no attribute" errors
                  reportOptionalMemberAccess = "none", -- Optional attribute access
                  reportOptionalSubscript = "none", -- Optional subscript access
                  reportOptionalCall = "none", -- Optional call
                  reportGeneralTypeIssues = "none", -- General type mismatches
                  reportOptionalIterable = "none", -- Optional iterable issues
                  reportOptionalContextManager = "none", -- Optional context manager
                  reportOptionalOperand = "none", -- Optional operand
                  reportUnknownMemberType = "none", -- Unknown member type
                  reportUnknownArgumentType = "none", -- Unknown argument type
                  reportUnknownVariableType = "none", -- Unknown variable type

                  -- Disable strict type assignment errors
                  reportAssignmentType = "none", -- "Expression of type X cannot be assigned to Y"
                  reportArgumentType = "none", -- "Argument of type X cannot be assigned to parameter Y"
                  reportReturnType = "none", -- Return type mismatches
                  reportCallIssue = "none", -- Call argument issues
                  reportIncompatibleMethodOverride = "none", -- Method override type issues
                  reportIncompatibleVariableOverride = "none", -- Variable override type issues
                  reportPossiblyUnboundVariable = "none", -- Possibly unbound variable

                  -- Disable unreachable code and operator errors
                  reportUnreachable = "none", -- "Code is unreachable"
                  reportOperatorIssue = "none", -- "Operator X is not supported for types Y and Z"
                  reportUnsupportedDunderAll = "none", -- __all__ issues
                  reportUnusedClass = "none", -- Unused class definitions
                  reportUnusedFunction = "none", -- Unused function definitions

                  -- Ignore line length complaints
                  reportLineLength = "none",
                },
              },
            },
            python = {
              formatting = {
                provider = "none", -- Don't use basedpyright's formatter
              },
            },
          },
        },
      },
    },
  },

  -- Enable flake8 linting (checks for errors without changing code)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "flake8" }, -- Use flake8 for linting
      },
      linters = {
        flake8 = {
          args = {
            "--max-line-length",
            "200",
            "--ignore",
            "E501", -- Ignore line-too-long
            "--format",
            "%(path)s:%(row)d:%(col)d: %(code)s %(text)s",
          },
        },
      },
    },
  },

  -- Use autopep8 to fix only specific PEP 8 errors (no line joining/splitting/continuation changes)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "autopep8" },
      },
      formatters = {
        autopep8 = {
          prepend_args = {
            "--max-line-length",
            "200",
            -- Only fix very specific codes that ONLY touch indentation/whitespace:
            -- E101: indentation contains mixed spaces and tabs
            -- E111: indentation is not a multiple of four
            -- E112: expected an indented block
            -- E113: unexpected indentation
            -- E114: indentation is not a multiple of four (comment)
            -- E115: expected an indented block (comment)
            -- E116: unexpected indentation (comment)
            -- E117: over-indented
            -- E201-E206: whitespace issues
            -- E211: whitespace before '('
            -- E221-E228: whitespace around operators (but not continuation)
            -- E231: missing whitespace
            -- E251: unexpected spaces around keyword / parameter equals
            -- E261-E266: inline comment issues
            -- E271-E276: whitespace issues
            -- E301-E306: blank line issues
            -- W291-W293: whitespace warnings
            "--select",
            "E101,E111,E112,E113,E114,E115,E116,E117,E201,E202,E203,E211,E221,E222,E223,E224,E225,E226,E227,E228,E231,E251,E261,E262,E265,E266,E271,E272,E273,E274,E275,E301,E302,E303,E304,E305,E306,W291,W292,W293",
            -- Explicitly ignore codes that touch line layout/continuation:
            "--ignore",
            "E121,E122,E123,E124,E125,E126,E127,E128,E129,E131,E501,E701,E702,E703,E704",
          },
        },
      },
    },
  },
}
