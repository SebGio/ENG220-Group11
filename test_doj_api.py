import requests

url = "https://www.justice.gov/api/v1/press_releases.json"

response = requests.get(
    url,
    params={
    "pagesize": 50,
    "parameters[title]": "New Mexico",
    "sort": "date",
    "direction": "DESC",
    "page": 0
},
)

response.raise_for_status()
data = response.json()

nm_office_id = "c20534dd-eed9-4241-aab0-6c85656d760f"
nm_articles = []

for article in data["results"]:
    components = article.get("component", [])

    belongs_to_nm = any(
        component.get("uuid") == nm_office_id
        for component in components
    )

    if belongs_to_nm:
        nm_articles.append(article)
        print("TITLE:", article.get("title"))
        print("URL:", article.get("url"))
        print()

print("Records checked:", len(data["results"]))
print("New Mexico records found:", len(nm_articles))