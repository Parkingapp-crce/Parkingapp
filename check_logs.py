from playwright.sync_api import sync_playwright

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.on("console", lambda msg: print(f"Browser console: {msg.text}"))
        page.on("pageerror", lambda err: print(f"Browser error: {err}"))
        try:
            page.goto("http://localhost:8105/", wait_until="networkidle")
            page.wait_for_timeout(3000)
        except Exception as e:
            print(e)
        browser.close()

if __name__ == "__main__":
    run()
