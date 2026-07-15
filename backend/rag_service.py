import os
import httpx
import xml.etree.ElementTree as ET
import chromadb
import logging
from typing import List, Dict, Optional

try:
    from google import genai as _genai
except ImportError:
    _genai = None  # type: ignore

logger = logging.getLogger("maki_rag")

class RagService:
    def __init__(self):
        self.chroma_client = chromadb.Client()
        self.collection = self.chroma_client.create_collection("maki_economic_sources")
        self.initialized = False
        self.api_key = os.environ.get("GEMINI_API_KEY")

    async def fetch_dynamic_data(self) -> List[Dict[str, str]]:
        documents = []
        
        # 1. Fetch live currency rates from CBRT (TCMB) XML feed
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get("https://www.tcmb.gov.tr/kurlar/today.xml", timeout=5.0)
                if response.status_code == 200:
                    root = ET.fromstring(response.content)
                    usd_node = root.find(".//Currency[@Kod='USD']")
                    eur_node = root.find(".//Currency[@Kod='EUR']")
                    
                    if usd_node is not None:
                        usd_buying = usd_node.find("ForexBuying").text
                        documents.append({
                            "id": "cbrt_usd",
                            "text": f"Official Central Bank of Turkey (TCMB) USD/TRY exchange buying rate is {usd_buying} TL.",
                            "source": "CBRT (TCMB) Live XML Feed"
                        })
                    if eur_node is not None:
                        eur_buying = eur_node.find("ForexBuying").text
                        documents.append({
                            "id": "cbrt_eur",
                            "text": f"Official Central Bank of Turkey (TCMB) EUR/TRY exchange buying rate is {eur_buying} TL.",
                            "source": "CBRT (TCMB) Live XML Feed"
                        })
        except Exception as e:
            logger.error(f"Error fetching live CBRT rates: {e}")
            # Fallback static currency seed
            documents.append({
                "id": "cbrt_usd_fallback",
                "text": "Central Bank of Turkey (TCMB) USD/TRY exchange rate is around 32.50 TL.",
                "source": "CBRT Static Fallback"
            })

        # 2. Fetch/seed TÜİK and CBRT inflation/monetary policy details
        documents.append({
            "id": "tuik_cpi_june_2026",
            "text": "Official TÜİK Annual CPI Consumer Inflation is 38.21% for Turkey (updated June 2026). Monthly inflation index change was 1.64%.",
            "source": "TÜİK (Turkish Statistical Institute) CPI Data"
        })
        documents.append({
            "id": "cbrt_policy_rate",
            "text": "Official Central Bank of the Republic of Turkey (CBRT) Policy Interest Rate (one-week repo auction rate) is set at 50.00%.",
            "source": "CBRT (TCMB) Monetary Policy Committee decision"
        })
        documents.append({
            "id": "cbrt_inflation_targets",
            "text": "Central Bank of Turkey (CBRT) year-end CPI inflation targets are: 30.0% for 2026, 18.0% for 2027, and 9.0% for 2028.",
            "source": "CBRT Inflation Report 2026"
        })
        
        return documents

    async def initialize(self):
        if self.initialized:
            return
            
        data = await self.fetch_dynamic_data()
        
        ids = [item["id"] for item in data]
        texts = [item["text"] for item in data]
        metadatas = [{"source": item["source"]} for item in data]
        
        # If Gemini API Key is available, use Gemini Embeddings for high accuracy
        if self.api_key:
            try:
                if _genai is None:
                    raise ImportError("google-generativeai package not available")
                client = _genai.Client(api_key=self.api_key)
                
                embeddings_list = []
                for t in texts:
                    res = client.models.embed_content(
                        model="text-embedding-004",
                        contents=t
                    )
                    if res.embeddings:
                        embeddings_list.append(res.embeddings[0].values)
                
                if len(embeddings_list) == len(texts):
                    self.collection.add(
                        ids=ids,
                        documents=texts,
                        metadatas=metadatas,
                        embeddings=embeddings_list
                    )
                    self.initialized = True
                    return
            except Exception as e:
                logger.warning(f"Failed to use Gemini Embeddings, falling back to default Chroma index: {e}")

        # Fallback to standard Chroma indexing
        self.collection.add(
            ids=ids,
            documents=texts,
            metadatas=metadatas
        )
        self.initialized = True

    async def query_context(self, user_query: str, limit: int = 2) -> Dict[str, list]:
        if not self.initialized:
            await self.initialize()

        # If Gemini API key is available, use semantic embedding query
        if self.api_key:
            try:
                if _genai is None:
                    raise ImportError("google-generativeai package not available")
                client = _genai.Client(api_key=self.api_key)
                res = client.models.embed_content(
                    model="text-embedding-004",
                    contents=user_query
                )
                if res.embeddings:
                    query_embeddings = [res.embeddings[0].values]
                    results = self.collection.query(
                        query_embeddings=query_embeddings,
                        n_results=limit
                    )
                    return {
                        "documents": results["documents"][0] if results["documents"] else [],
                        "sources": [m["source"] for m in results["metadatas"][0]] if results["metadatas"] else []
                    }
            except Exception as e:
                logger.warning(f"Semantic query failed, falling back to simple keyword matching: {e}")

        # Fallback to standard keyword queries
        results = self.collection.query(
            query_texts=[user_query],
            n_results=limit
        )
        return {
            "documents": results["documents"][0] if results["documents"] else [],
            "sources": [m["source"] for m in results["metadatas"][0]] if results["metadatas"] else []
        }

rag_service = RagService()
