import asyncio
import time
import logging
from pathlib import Path

from langchain_core.documents import Document
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS

logger = logging.getLogger("neural.embeddings")

ASSETS_PATH = Path(__file__).parent / "assets"


def _load_hf_embeddings() -> HuggingFaceEmbeddings:
    return HuggingFaceEmbeddings(
        model_name="deepvk/USER-bge-m3",
        model_kwargs={"device": "cpu"},
        encode_kwargs={"normalize_embeddings": True},
    )


class Embeddings:
    def __init__(self) -> None:
        self.embeddings: HuggingFaceEmbeddings | None = None
        self.vectorstore = None
        self._retriever = None

    async def initialize(self) -> None:
        # Load HuggingFace model in a thread — it's CPU-heavy and blocks the event loop
        self.embeddings = await asyncio.to_thread(_load_hf_embeddings)
        logger.info("HuggingFace embeddings model loaded")

        faiss_path = ASSETS_PATH / "faiss" / "exercizes"
        if faiss_path.exists():
            self.vectorstore = await asyncio.to_thread(
                FAISS.load_local,
                str(faiss_path),
                self.embeddings,
                allow_dangerous_deserialization=True,
            )
            logger.info("FAISS index loaded from cache")
        else:
            docs = await self._load_document()
            self.vectorstore = await asyncio.to_thread(
                FAISS.from_documents, docs, self.embeddings
            )
            faiss_path.mkdir(parents=True, exist_ok=True)
            await asyncio.to_thread(self.vectorstore.save_local, str(faiss_path))
            logger.info("FAISS index built and saved")

        self._retriever = self.vectorstore.as_retriever(
            search_type="mmr",
            search_kwargs={"k": 100, "fetch_k": 1000, "lambda_mult": 0.9},
        )

    async def _load_document(self) -> list[Document]:
        docs_path = ASSETS_PATH / "docs" / "exercizes.md"
        text = await asyncio.to_thread(docs_path.read_text, encoding="utf-8")
        blocks = text.split("## Exercise")
        documents = []
        for block in blocks[1:]:
            data = {}
            for line in block.strip().split("\n"):
                if ":" in line:
                    key, value = line.split(":", 1)
                    data[key.strip()] = value.strip()
            documents.append(Document(page_content=block, metadata=data))
        return documents

    async def search_exercises_by_query(self, query: str, to_string: bool = False):
        t0 = time.perf_counter()
        result = await self._retriever._aget_relevant_documents(query, run_manager=None)
        logger.info(f"FAISS search took {time.perf_counter() - t0:.3f}s, got {len(result)} docs")
        if not to_string:
            return result
        return "\n".join(
            f"{e.metadata['id']}: {e.metadata['Название']} ({e.metadata['Мышечная группа']})"
            for e in result
        )
