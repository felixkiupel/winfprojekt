from cryptography.fernet import Fernet
import os

# Load Fernet key from .env
FERNET_KEY = os.getenv("FERNET_KEY")

if not FERNET_KEY:
    raise ValueError("FERNET_KEY is missing! Please add it to your .env file.")

fernet = Fernet(FERNET_KEY)

def encrypt_field(value: str) -> str:
    """Encrypt a field using Fernet symmetric encryption."""
    return fernet.encrypt(value.encode()).decode()

def decrypt_field(value: str) -> str:
    """Decrypt a field using Fernet symmetric encryption."""
    return fernet.decrypt(value.encode()).decode()
