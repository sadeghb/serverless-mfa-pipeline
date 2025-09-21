# src/utils/config_loader.py

from pathlib import Path

import yaml

# Define the path to the configuration file relative to the project root.
CONFIG_PATH = Path("config.yaml")


def load_config():
    """
    Loads and parses the main YAML configuration file for the application.

    Raises:
        FileNotFoundError: If the configuration file does not exist at the
                           expected path.

    Returns:
        A dictionary containing the application configuration.
    """
    if not CONFIG_PATH.exists():
        raise FileNotFoundError(f"Configuration file not found at: {CONFIG_PATH}")

    with open(CONFIG_PATH, 'r') as f:
        config = yaml.safe_load(f)
    return config
