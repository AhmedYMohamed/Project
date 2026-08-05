from ollama import chat, ChatResponse

def ask_llm(prompt:str) -> str:

    model="llama3.1"
    response = chat(model=model, 
                                messages=[
                                    {"role": "user",
                                     "content": prompt}
                                    ])
    res = response['message']['content'].strip()
    return res