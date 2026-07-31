import logging
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def check_url_accessibility(url, timeout=10):
    """Return True when the URL can be reached, otherwise log and return False."""
    if not url:
        logger.error("URL check skipped because the provided URL is empty")
        return False

    try:
        request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urlopen(request, timeout=timeout) as response:
            status = getattr(response, "status", None)
            logger.info("URL check succeeded for %s (status=%s)", url, status)
            return True
    except HTTPError as exc:
        logger.warning("URL check reached %s but returned HTTP %s", url, exc.code)
        return False
    except (URLError, TimeoutError, ValueError, OSError) as exc:
        logger.exception("Unable to access URL %s: %s", url, exc)
        return False
    except Exception as exc:
        logger.exception("Unexpected error while checking URL %s: %s", url, exc)
        return False


def build_chrome_options():
    """Create a Chrome options object with common reliability flags."""
    try:
        from selenium.webdriver.chrome.options import Options
    except Exception as exc:
        logger.exception("Unable to import Selenium Chrome options: %s", exc)
        raise

    options = Options()
    common_arguments = [
        "--disable-dev-shm-usage",
        "--no-sandbox",
        "--disable-gpu",
        "--disable-software-rasterizer",
        "--disable-extensions",
        "--disable-background-networking",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding",
        "--disable-features=Translate,BackForwardCache",
        "--window-size=1920,1080",
        "--start-maximized",
        "--ignore-certificate-errors",
        "--disable-popup-blocking",
        "--remote-allow-origins=*",
    ]

    for argument in common_arguments:
        options.add_argument(argument)

    logger.info("Built Chrome options with %s reliability flags", len(common_arguments))
    return options
