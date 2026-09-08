import requests; import flask; import subprocess;import time
url = ""
payload = {}

print("evil catalog adding python tool (made by mudkip 2026)")
payload["id"] = input("ID: ")
payload["name"] = input("name: ")
payload["description"] = input("desc: ")
payload["price"] = input("price: ")
payload["stock"] = input("stock: ")
payload["pack"] = input("pack: ")
payload["locked"] = False
print("fetching,")
response = requests.post(
    url="http://vps-2ddc970b.vps.ovh.net:9142/api/catalog",
    headers=({"Authorization": "Bearer c48c42e49730405b65a1fe94e813a601b18273cab760fbfec02635d1457c8356","Content-Type": "application/json"}),
    json=(payload),
    timeout=30
)
print(response)
response.raise_for_status()