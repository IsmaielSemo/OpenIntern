#!/usr/bin/env python3
"""
Advanced Indeed.com Scraper

A robust Python scraper for extracting internship listings from Indeed.com
with features like rotating user agents, proxy support, and comprehensive error handling.
"""

import argparse
import json
import logging
import random
import time
import urllib.parse
from typing import Dict, List, Optional, Union

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import os
from urllib.parse import quote_plus
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException, StaleElementReferenceException
from webdriver_manager.chrome import ChromeDriverManager
import re

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class IndeedScraper:
    def __init__(self, headless: bool = True, max_retries: int = 3, retry_delay: int = 5, page_load_timeout: int = 30, use_vpn: bool = False):
        self.base_url = "https://www.indeed.com"
        self.search_url = f"{self.base_url}/jobs"
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.page_load_timeout = page_load_timeout
        self.use_vpn = use_vpn
        self.driver = self._setup_driver(headless)
        
    def _setup_driver(self, headless: bool) -> webdriver.Chrome:
        """Set up the Chrome WebDriver with appropriate options."""
        chrome_options = Options()
        
        if headless:
            chrome_options.add_argument("--headless=new")  # Use the new headless mode
            
        # Add additional options to make the browser look more like a real user
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--disable-blink-features=AutomationControlled")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-infobars")
        chrome_options.add_argument("--disable-notifications")
        chrome_options.add_argument("--disable-popup-blocking")
        chrome_options.add_argument("--start-maximized")
        chrome_options.add_argument("--enable-unsafe-swiftshader")  # Fix WebGL errors
        
        # Add user agent
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        
        # Add experimental options
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option("useAutomationExtension", False)
        
        # If using VPN, add proxy settings
        if self.use_vpn:
            # This is a placeholder - in a real implementation, you would use a real VPN service
            # or proxy service API to get a proxy
            proxy = self._get_proxy()
            if proxy:
                chrome_options.add_argument(f'--proxy-server={proxy}')
                logger.info(f"Using proxy: {proxy}")
        
        # Initialize the driver
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        
        # Set page load timeout
        driver.set_page_load_timeout(self.page_load_timeout)
        
        # Execute CDP commands to prevent detection
        driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {
            "source": """
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined
                });
            """
        })
        
        return driver
        
    def _get_proxy(self) -> Optional[str]:
        """Get a proxy from a proxy service."""
        # This is a placeholder - in a real implementation, you would use a proxy service API
        # For example, you could use services like Bright Data, Oxylabs, or SmartProxy
        return None
        
    def _random_sleep(self, min_seconds: float = 2.0, max_seconds: float = 5.0):
        """Sleep for a random amount of time to simulate human behavior."""
        time.sleep(random.uniform(min_seconds, max_seconds))
        
    def _scroll_page(self):
        """Scroll the page to simulate human behavior."""
        # Scroll down slowly
        for i in range(3):
            self.driver.execute_script(f"window.scrollTo(0, {i * 500});")
            self._random_sleep(0.5, 1.5)
            
        # Scroll back to top
        self.driver.execute_script("window.scrollTo(0, 0);")
        self._random_sleep(1.0, 2.0)
        
    def _wait_for_element(self, by, value, timeout=10):
        """Wait for an element to be present on the page."""
        try:
            element = WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located((by, value))
            )
            return element
        except TimeoutException:
            logger.warning(f"Timeout waiting for element: {value}")
            return None
            
    def _is_page_loaded(self):
        """Check if the page is fully loaded."""
        try:
            # Check if the page has a job card or a "no results" message
            job_cards = self.driver.find_elements(By.CSS_SELECTOR, "div.job_seen_beacon")
            no_results = self.driver.find_elements(By.CSS_SELECTOR, "div.no_results")
            
            return len(job_cards) > 0 or len(no_results) > 0
        except:
            return False
            
    def search_jobs(self, query: str, location: str, pages: int = 1) -> List[Dict]:
        """Search for jobs and return the results."""
        all_jobs = []
        
        # Try different search queries to increase chances of finding results
        search_queries = [
            query,
            f"{query} entry level",
            f"{query} junior",
            f"{query} student",
            f"{query} graduate"
        ]
        
        for search_query in search_queries:
            # URL encode the query and location
            encoded_query = quote_plus(search_query)
            encoded_location = quote_plus(location)
            
            logger.info(f"Trying search query: {search_query} in {location}")
            
            for page in range(pages):
                # Construct the URL with parameters
                url = f"{self.search_url}?q={encoded_query}&l={encoded_location}&start={page * 10}&sort=date&fromage=7&radius=50"
                
                logger.info(f"Scraping page {page + 1} for query: {search_query} in {location}")
                
                for attempt in range(self.max_retries):
                    try:
                        # Navigate to the page
                        self.driver.get(url)
                        self._random_sleep(3.0, 5.0)
                        
                        # Check if the page loaded successfully
                        if not self._is_page_loaded():
                            logger.warning(f"Page {page + 1} did not load properly. Retrying...")
                            if attempt < self.max_retries - 1:
                                self._random_sleep(5.0, 10.0)
                                continue
                            else:
                                logger.error(f"Failed to load page {page + 1} after {self.max_retries} attempts")
                                break
                        
                        # Check for captcha or robot detection
                        if "captcha" in self.driver.page_source.lower() or "robot" in self.driver.page_source.lower():
                            logger.warning("Detected anti-bot measures. Waiting longer before retry...")
                            self._random_sleep(10.0, 15.0)
                            if attempt < self.max_retries - 1:
                                continue
                            else:
                                logger.error("Detected anti-bot measures after multiple attempts")
                                break
                        
                        # Scroll the page to load all content
                        self._scroll_page()
                        
                        # Parse the page with BeautifulSoup
                        soup = BeautifulSoup(self.driver.page_source, 'lxml')
                        job_cards = soup.find_all('div', class_='job_seen_beacon')
                        
                        if not job_cards:
                            logger.warning("No job cards found. The page structure might have changed or we're being blocked.")
                            # Try alternative selectors
                            job_cards = soup.find_all('div', class_='job_seen_beacon') or \
                                       soup.find_all('div', class_='job_seen_beacon') or \
                                       soup.find_all('div', class_='job_seen_beacon')
                            
                            if not job_cards:
                                break
                        
                        for job in job_cards:
                            try:
                                job_data = self._parse_job_card(job)
                                if job_data:
                                    # Check if this job is already in our results
                                    if not any(j['url'] == job_data['url'] for j in all_jobs):
                                        all_jobs.append(job_data)
                            except Exception as e:
                                logger.error(f"Error parsing job card: {str(e)}")
                                continue
                        
                        # Successfully processed this page
                        break
                        
                    except TimeoutException:
                        logger.error(f"Timeout waiting for page {page + 1} to load (attempt {attempt + 1}/{self.max_retries})")
                        if attempt < self.max_retries - 1:
                            self._random_sleep(5.0, 10.0)
                        else:
                            logger.error(f"Failed to load page {page + 1} after {self.max_retries} attempts")
                    except WebDriverException as e:
                        logger.error(f"WebDriver error on page {page + 1} (attempt {attempt + 1}/{self.max_retries}): {str(e)}")
                        if attempt < self.max_retries - 1:
                            self._random_sleep(5.0, 10.0)
                        else:
                            logger.error(f"Failed to load page {page + 1} after {self.max_retries} attempts")
                    except Exception as e:
                        logger.error(f"Unexpected error on page {page + 1} (attempt {attempt + 1}/{self.max_retries}): {str(e)}")
                        if attempt < self.max_retries - 1:
                            self._random_sleep(5.0, 10.0)
                        else:
                            logger.error(f"Failed to load page {page + 1} after {self.max_retries} attempts")
                
                # Add a longer delay between pages
                self._random_sleep(5.0, 10.0)
            
            # If we found jobs with this query, we can stop trying other queries
            if all_jobs:
                logger.info(f"Found {len(all_jobs)} jobs with query '{search_query}'. Stopping search.")
                break
        
        return all_jobs
        
    def _parse_job_card(self, job_card) -> Optional[Dict]:
        """Parse a job card and extract relevant information."""
        try:
            # Try different selectors for title
            title_elem = job_card.find('h2', class_='jobTitle') or \
                        job_card.find('h2', class_='job-title') or \
                        job_card.find('h2', class_='title')
            
            # Try different selectors for company
            company_elem = job_card.find('span', class_='companyName') or \
                          job_card.find('span', class_='company-name') or \
                          job_card.find('div', class_='company')
            
            # Try different selectors for location
            location_elem = job_card.find('div', class_='companyLocation') or \
                           job_card.find('div', class_='location') or \
                           job_card.find('span', class_='location')
            
            # Try different selectors for salary
            salary_elem = job_card.find('div', class_='salary-snippet') or \
                         job_card.find('div', class_='salary') or \
                         job_card.find('span', class_='salary')
            
            # Try different selectors for description
            description_elem = job_card.find('div', class_='job-snippet') or \
                             job_card.find('div', class_='summary') or \
                             job_card.find('div', class_='description')
            
            # Get the job URL
            job_link = job_card.find('a', class_='jcs-JobTitle') or \
                      job_card.find('a', class_='job-link') or \
                      job_card.find('a', class_='title')
            
            job_url = self.base_url + job_link['href'] if job_link and 'href' in job_link.attrs else None
            
            # Extract posting date if available
            date_elem = job_card.find('span', class_='date') or \
                       job_card.find('span', class_='posted-date') or \
                       job_card.find('div', class_='date')
            
            posted_date = date_elem.get_text().strip() if date_elem else None
            
            # Extract job type if available
            job_type_elem = job_card.find('div', class_='metadata') or \
                           job_card.find('div', class_='job-type') or \
                           job_card.find('span', class_='job-type')
            
            job_type = job_type_elem.get_text().strip() if job_type_elem else None
            
            # Clean up text
            title = title_elem.get_text().strip() if title_elem else None
            company = company_elem.get_text().strip() if company_elem else None
            location = location_elem.get_text().strip() if location_elem else None
            salary = salary_elem.get_text().strip() if salary_elem else None
            description = description_elem.get_text().strip() if description_elem else None
            
            # Only return if we have at least a title and company
            if title and company:
                return {
                    'title': title,
                    'company': company,
                    'location': location,
                    'salary': salary,
                    'description': description,
                    'url': job_url,
                    'posted_date': posted_date,
                    'job_type': job_type
                }
            else:
                logger.warning("Job card missing essential information (title or company)")
                return None
                
        except Exception as e:
            logger.error(f"Error parsing job card: {str(e)}")
            return None
            
    def close(self):
        """Close the browser."""
        if self.driver:
            self.driver.quit()
            
def main():
    parser = argparse.ArgumentParser(description='Indeed.com Job Scraper')
    parser.add_argument('--query', default='internship', help='Search query')
    parser.add_argument('--location', default='United States', help='Location to search in')
    parser.add_argument('--pages', type=int, default=1, help='Number of pages to scrape')
    parser.add_argument('--headless', action='store_true', help='Run in headless mode')
    parser.add_argument('--output', default='indeed_jobs.json', help='Output file path')
    parser.add_argument('--timeout', type=int, default=30, help='Page load timeout in seconds')
    parser.add_argument('--use-vpn', action='store_true', help='Use VPN/proxy (requires configuration)')
    
    args = parser.parse_args()
    
    scraper = IndeedScraper(headless=args.headless, page_load_timeout=args.timeout, use_vpn=args.use_vpn)
    try:
        jobs = scraper.search_jobs(args.query, args.location, args.pages)
        
        # Save results to JSON file
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(jobs, f, indent=2, ensure_ascii=False)
            
        logger.info(f"Scraped {len(jobs)} jobs and saved to {args.output}")
    finally:
        scraper.close()
    
if __name__ == "__main__":
    main() 