import os
import shutil
import threading
import gradio as gr
from Data_Indexing.pipeline_DataLoad import DataPipeline

# ---------------------------------------------------------------------------
# Custom CSS for professional UI
# ---------------------------------------------------------------------------
CUSTOM_CSS = """
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

body, .gradio-container {
    font-family: 'Inter', sans-serif !important;
    background-color: #f3f4f6 !important;
    color: #111827 !important;
}

.sidebar {
    background: #ffffff !important;
    border-right: 1px solid #e5e7eb !important;
    border-radius: 0 16px 16px 0 !important;
    padding: 2rem 1.5rem !important;
    box-shadow: 4px 0 24px rgba(0,0,0,0.04);
}

.sidebar h1, .sidebar h2, .sidebar h3 {
    color: #111827 !important;
    font-weight: 700 !important;
}

.gr-button-primary {
    background: #4f46e5 !important;
    color: #ffffff !important;
    font-weight: 600 !important;
    border: none !important;
    border-radius: 12px !important;
    box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);
    transition: all 0.2s ease;
}

.gr-button-primary:hover {
    background: #4338ca !important;
    box-shadow: 0 6px 16px rgba(79, 70, 229, 0.35);
}

.main-area {
    background: #ffffff !important;
    border-radius: 16px !important;
    border: 1px solid #e5e7eb !important;
    padding: 2rem !important;
    box-shadow: 0 4px 24px rgba(0,0,0,0.04);
}

.chatbot .message.user {
    background: #eef2ff !important;
    color: #312e81 !important;
    border-radius: 18px 18px 4px 18px !important;
}

.chatbot .message.bot {
    background: #f9fafb !important;
    color: #111827 !important;
    border-radius: 18px 18px 18px 4px !important;
}

.stop-btn {
    background: #ef4444 !important;
    color: #ffffff !important;
    font-weight: 600 !important;
    border: none !important;
    border-radius: 12px !important;
}

.stop-btn:hover {
    background: #dc2626 !important;
}
"""

# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------
rag_pipeline = DataPipeline(pdf_path=None, verbose=True)
stop_event = threading.Event()

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
def handle_upload(file_obj):
    """Handle PDF upload and indexing."""
    if file_obj is None:
        return "⚠️ Please upload a PDF file.", "❌ No document loaded"
    
    try:
        status = rag_pipeline.reload_from_upload(file_obj.name)
        doc_info = f"📄 {os.path.basename(file_obj.name)} | 🧩 {rag_pipeline.num_chunks} chunks"
        return status, doc_info
    except Exception as e:
        return f"❌ Error: {str(e)}", "❌ Failed to load document"


def clear_index():
    """Clear the FAISS index and reset pipeline."""
    if os.path.exists("faiss_index"):
        shutil.rmtree("faiss_index")
    rag_pipeline.vector_store = None
    rag_pipeline.pdf_path = None
    rag_pipeline.num_chunks = 0
    rag_pipeline.history.clear()
    stop_event.clear()
    return "🗑️ Index cleared. Upload a new PDF to start.", "❌ No document loaded"


def respond(message, history):
    """Generate response using RAG pipeline."""
    if rag_pipeline.vector_store is None:
        return (
            "",
            history + [
                {"role": "user", "content": message},
                {"role": "assistant", "content": "❌ Please upload a PDF first!"}
            ],
            gr.update(interactive=True),
            gr.update(interactive=False),
        )

    stop_event.clear()
    try:
        response_text = rag_pipeline.llm_response(message)
    except Exception as e:
        response_text = f"❌ Error: {str(e)}"

    return (
        "",
        history + [
            {"role": "user", "content": message},
            {"role": "assistant", "content": response_text}
        ],
        gr.update(interactive=True),
        gr.update(interactive=False),
    )


def stop_generation():
    """Stop generation."""
    stop_event.set()


def clear_chat():
    """Clear chat history."""
    rag_pipeline.history.clear()


# ---------------------------------------------------------------------------
# UI Layout
# ---------------------------------------------------------------------------
with gr.Blocks(css=CUSTOM_CSS) as demo:
    with gr.Row(equal_height=True):
        # Sidebar
        with gr.Column(scale=1, elem_classes="sidebar"):
            gr.Markdown("# 📚 RAG Assistant")
            gr.Markdown("Upload a PDF and start chatting with its content.")
            gr.Markdown("---")

            pdf_upload = gr.File(
                label="Upload PDF",
                file_types=[".pdf"]
            )
            index_btn = gr.Button("🔍 Index Document", variant="primary")

            status_text = gr.Textbox(
                label="Status",
                value="🗑️ No index loaded",
                interactive=False,
                lines=2
            )

            doc_info = gr.Textbox(
                label="Current Document",
                value="❌ No document loaded",
                interactive=False
            )

            gr.Markdown("---")
            clear_btn = gr.Button("🗑️ Clear Index", variant="secondary")

            gr.Markdown("---")
            gr.Markdown("### 💡 Example Questions")
            examples = [
                "What is the main topic?",
                "Summarize the document.",
                "What are key findings?",
            ]
            for ex in examples:
                gr.Markdown(f"- *{ex}*")

        # Main chat area
        with gr.Column(scale=3, elem_classes="main-area"):
            gr.Markdown("## 💬 Chat with your PDF")

            chatbot = gr.Chatbot(height=500, elem_classes="chatbot")

            msg_input = gr.Textbox(
                placeholder="Type your question here...",
                show_label=False,
                container=False,
                lines=3
            )

            with gr.Row():
                submit_btn = gr.Button("➤ Send", variant="primary", scale=1)
                stop_btn = gr.Button("⏹ Stop", elem_classes="stop-btn", scale=0, interactive=False)

    # Event wiring
    index_btn.click(
        fn=handle_upload,
        inputs=pdf_upload,
        outputs=[status_text, doc_info]
    )

    clear_btn.click(
        fn=clear_index,
        outputs=[status_text, doc_info]
    )

    submit_btn.click(
        fn=respond,
        inputs=[msg_input, chatbot],
        outputs=[msg_input, chatbot, submit_btn, stop_btn]
    )

    msg_input.submit(
        fn=respond,
        inputs=[msg_input, chatbot],
        outputs=[msg_input, chatbot, submit_btn, stop_btn]
    )

    stop_btn.click(fn=stop_generation)

if __name__ == "__main__":
    demo.launch(share=False)
