"""Permissions are reconciled by grant_permissions; no blanket revoke is safe in shared instances."""
from rbac import configure
if __name__ == "__main__": configure()
