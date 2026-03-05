from fastapi import FastAPI

app = FastAPI(title="Product Service")

products = [
    {"id": 1, "name": "Laptop", "price": 999.00},
    {"id": 2, "name": "Mouse", "price": 29.00},
]

@app.get("/api/products")
def get_products():
    return products

@app.get("/api/products/{product_id}")
def get_product(product_id: int):
    for p in products:
        if p["id"] == product_id:
            return p
    return {"error": "Product not found"}

@app.get("/api/products/search")
def search_products(name: str = ""):
    return [p for p in products if name.lower() in p["name"].lower()]

@app.get("/health")
def health():
    return {"status": "ok", "service": "product-service", "version": "1.0.1"}
