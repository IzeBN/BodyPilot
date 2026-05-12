from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    db_dsn: str
    db_min_pool: int = 10
    db_max_pool: int = 50

    jwt_secret: str
    jwt_access_expire_minutes: int = 15
    jwt_refresh_expire_days: int = 30
    jwt_algorithm: str = "HS256"

    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_proxy: str = ""

    anthropic_api_key: str = ""

    yookassa_shop_id: str = ""
    yookassa_secret_key: str = ""
    yookassa_return_url: str = "https://fitkeep.online/payment-result"

    firebase_credentials_path: str = ""

    telegram_bot_token: str = ""
    telegram_managers_chat_id: int = 0
    telegram_users_chat_id: int = 0

    admin_user_ids: str = ""

    @property
    def admin_ids(self) -> set[int]:
        return {int(x.strip()) for x in self.admin_user_ids.split(",") if x.strip().isdigit()}


@lru_cache
def get_settings() -> Settings:
    return Settings()
