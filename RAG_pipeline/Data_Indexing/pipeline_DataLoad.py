import os
import shutil

# تحديث المكتبات المطلوبة (LangChain)
from langchain_community.document_loaders import PyPDFDirectoryLoader, PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS

import sys
import os

# إضافة المسار الرئيسي للمشروع عشان بايثون يشوف فولدر Generation
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.append(BASE_DIR)

from Generation.llm import ask_llm
class DataPipeline:
    # نقدر نمرر مسار لملف واحد أو مسار لـ "فولدر" كامل مليان كتب PDF
    def __init__(self, pdf_path:str=None, verbose:bool=True):
        self.pdf_path = pdf_path
        self.history = [] 
        self.k = 5 
        self.verbose = verbose
        self.num_chunks = 0
        self.vector_store = None
        if pdf_path:
            self.vector_store = self.build_vector_store()

    def _log(self, title, content):
        if self.verbose:
            print(f"\n{'=' * 60}")
            print(f"  {title}")
            print('=' * 60)
            print(content)

    def reload_from_upload(self, file_path: str) -> str:
        """يقبل مسار ملف جديد أو فولدر، يمسح الذاكرة القديمة ويبنيها من جديد"""
        if not file_path or not os.path.exists(file_path):
            return "❌ Error: File or directory not found."
        
        if os.path.exists("faiss_index"):
            shutil.rmtree("faiss_index")
            
        self.pdf_path = file_path
        self.history.clear()
        try:
            self.vector_store = self.build_vector_store()
            return f"✅ Successfully indexed. Chunks created: {self.num_chunks}"
        except Exception as e:
            return f"❌ Error during indexing: {str(e)}"

    def DataSpliting(self):
        """تحميل الكتب وتقطيعها بذكاء يحافظ على النصوص القانونية"""
        try:
            # 1. التحقق هل المسار لفولدر كامل أم ملف واحد
            if os.path.isdir(self.pdf_path):
                self._log("LOADER", f"Loading all PDFs from directory: {self.pdf_path}")
                loader = PyPDFDirectoryLoader(self.pdf_path)
            else:
                self._log("LOADER", f"Loading single PDF: {self.pdf_path}")
                loader = PyPDFLoader(self.pdf_path)
                
            documents = loader.load()

            # 2. التقطيع الذكي (Smart Chunking)
            # نستخدم فواصل اللغة العربية والقانون لعدم قطع المواد في المنتصف
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=150,
                separators=["\nالمادة", "\nالباب", "\nالفصل", "\n\n", "\n", " ", ""]
            )
            
            chunks = text_splitter.split_documents(documents)
            self.num_chunks = len(chunks)
            self._log("DOCUMENTS LOADED", f"Loaded {len(chunks)} smart chunks from PDFs.")
            
            return chunks
            
        except Exception as e:
            self._log("ERROR LOADING PDF", str(e))
            raise

    def build_vector_store(self, model_embedding="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"):
        if os.path.exists("faiss_index"):
            self.vector_store = FAISS.load_local("faiss_index", HuggingFaceEmbeddings(model_name=model_embedding), allow_dangerous_deserialization=True)
        else:
            if not self.pdf_path:
                raise ValueError("No PDF path provided and no existing FAISS index found.")
            
            docs = self.DataSpliting()
            if not docs:
                raise ValueError("No documents were loaded. Please check the path.")
            
            print("⏳ جاري تحميل نموذج تحويل النصوص وبناء الذاكرة (سيكون أسرع بكثير)...")
            # استخدام نموذج مخصص للغات من HuggingFace
            embeddings = HuggingFaceEmbeddings(model_name=model_embedding)
            self.vector_store = FAISS.from_documents(docs, embeddings)
            self.vector_store.save_local("faiss_index")
            print("✅ تم بناء الذاكرة وحفظها بنجاح!")
            
        return self.vector_store

    def retrieve_with_score(self, question:str, top_k:int=5, score_threshold:float=1.0):
        # البحث عن أقرب المواد القانونية
        matched_docs = self.vector_store.similarity_search_with_score(question, k=top_k)
        
        context = ""
        log_chunks = ""
        
        for i, (doc, chunk_score) in enumerate(matched_docs):
            # استخراج اسم الكتاب ورقم الصفحة لتوثيق الرد
            source = os.path.basename(doc.metadata.get('source', 'كتاب غير معروف'))
            page = doc.metadata.get('page', 0) + 1 # +1 لأن البرمجة تبدأ من 0
            
            # تجهيز السياق ليقرأه الموديل مع التوثيق
            context += f"[المصدر: {source} | صفحة: {page}]\n{doc.page_content}\n\n"
            
            preview = doc.page_content[:150] + "..." if len(doc.page_content) > 150 else doc.page_content
            log_chunks += f"\n[Chunk {i+1}] Source: {source} | Page: {page} | Score: {chunk_score:.4f}\n{preview}\n"

        self._log("RETRIEVED CHUNKS", log_chunks if log_chunks else "(none found)")
        
        context = context if context else "No relevant information found; please answer the question directly based on your general knowledge."
        return context
    
    def build_prompt(self, context, history, input, template=''):
        if template:
            self.template = template
        else:
            # تعديل الـ Prompt ليجبر الموديل على ذكر اسم الكتاب ورقم المادة
            self.template = """
            ### System:
            أنت مساعد ذكي ومستشار قانوني لغرفة عمليات وزارة الداخلية. 
            يجب عليك الإجابة على السؤال بناءً على "السياق القانوني" المقدم لك فقط بدقة شديدة.
            مهم جداً: عند الإجابة، يجب عليك ذكر اسم الكتاب ورقم الصفحة الذي استندت إليه في إجابتك (موجود في السياق).

            ### Current conversation:
            {history}

            ### Context (السياق القانوني):
            {context}

            ### Question:
            {input}

            ### AI Assistant:
            """
        return self.template.format(history=history, context=context, input=input)

    def llm_response(self, input):
        self._log("USER QUESTION", input)

        context = self.retrieve_with_score(input)

        history = ""
        for user_msg, ai_msg in self.history:
            history += f"User: {user_msg}\nAI Assistant: {ai_msg}\n"
        self._log("CONVERSATION HISTORY", history if history else "(no history yet)")

        prompt = self.build_prompt(context=context, history=history, input=input)
        self._log("FULL PROMPT SENT TO MODEL", prompt)

        response = ask_llm(prompt)
        self._log("MODEL RESPONSE", response)

        self.history.append((input, response))
        if len(self.history) > self.k:
            self.history.pop(0)
            
        return response