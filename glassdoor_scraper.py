import json
import time
import random
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, ElementClickInterceptedException
from selenium.webdriver.chrome.options import Options
from datetime import datetime
import re

class GlassdoorScraper:
    def __init__(self):
        self.base_url = "https://www.glassdoor.com/Job/egypt-software-intern-jobs-SRCH_IL.0,5_IN69_KO6,21.htm"
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
        ]
        self.setup_driver()
        
    def setup_driver(self):
        chrome_options = Options()
        chrome_options.add_argument(f'user-agent={random.choice(self.user_agents)}')
        chrome_options.add_argument('--headless=new')
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-software-rasterizer')
        chrome_options.add_argument('--disable-webgl')
        chrome_options.add_argument('--window-size=1920,1080')
        chrome_options.add_argument('--disable-notifications')
        chrome_options.add_argument('--disable-popup-blocking')
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.wait = WebDriverWait(self.driver, 10)
        
    def debug_element(self, element, context=""):
        """Helper function to debug elements"""
        try:
            print(f"\nDebugging {context}:")
            print(f"Text content: {element.text}")
            print(f"HTML content: {element.get_attribute('outerHTML')}")
            print(f"Class names: {element.get_attribute('class')}")
        except Exception as e:
            print(f"Error debugging element: {str(e)}")

    def handle_popups(self):
        """Handle common Glassdoor popups"""
        try:
            # List of common popup/overlay selectors
            overlay_selectors = [
                "[aria-label='Modal Window']",
                ".modal",
                "#LoginModal",
                "[role='dialog']",
                ".popup"
            ]
            
            # Try to find and close any overlays
            for selector in overlay_selectors:
                try:
                    overlay = self.driver.find_element(By.CSS_SELECTOR, selector)
                    if overlay.is_displayed():
                        print(f"Found overlay with selector: {selector}")
                        # Try to find close button within the overlay
                        close_selectors = [
                            "button[aria-label='Close']",
                            ".modal_closeIcon",
                            ".close",
                            "[title='Close']",
                            "button.closeButton"
                        ]
                        
                        for close_selector in close_selectors:
                            try:
                                close_btn = overlay.find_element(By.CSS_SELECTOR, close_selector)
                                if close_btn.is_displayed():
                                    close_btn.click()
                                    print(f"Closed popup using selector: {close_selector}")
                                    time.sleep(1)
                                    return
                            except:
                                continue
                        
                        # If no close button found, try clicking outside
                        try:
                            self.driver.execute_script(
                                "arguments[0].style.display = 'none';", overlay
                            )
                            print("Removed overlay using JavaScript")
                        except:
                            pass
                except:
                    continue
                    
        except Exception as e:
            print(f"Error handling popups: {str(e)}")

    def wait_for_element(self, selector, timeout=10, parent=None):
        """Wait for an element to be present and visible"""
        try:
            element = None
            end_time = time.time() + timeout
            
            while time.time() < end_time:
                try:
                    if parent:
                        element = parent.find_element(By.CSS_SELECTOR, selector)
                    else:
                        element = self.driver.find_element(By.CSS_SELECTOR, selector)
                        
                    if element.is_displayed():
                        return element
                except:
                    time.sleep(0.5)
                    
            return None
        except Exception as e:
            print(f"Error waiting for element {selector}: {str(e)}")
            return None

    def get_job_details_from_card(self, job_card):
        """Extract job details directly from the card without clicking"""
        try:
            print("\nExtracting job details from card...")
            
            # Get the parent article element that contains all job info
            article = job_card.find_element(By.XPATH, "./ancestor::article")
            self.debug_element(article, "Job Article")
            
            # Extract title
            title = None
            title_selectors = [
                ".//div[contains(@class, 'job-title')]",
                ".//a[@data-test='job-link']",
                ".//span[contains(@class, 'jobTitle')]"
            ]
            for selector in title_selectors:
                try:
                    title_elem = article.find_element(By.XPATH, selector)
                    if title_elem.is_displayed():
                        title = title_elem.text.strip()
                        if title:
                            break
                except:
                    continue
                
            if not title:
                print("Could not find title")
                return None
            
            # Extract company
            company = None
            company_selectors = [
                ".//div[contains(@class, 'employer-name')]",
                ".//span[contains(@class, 'employer')]",
                ".//a[contains(@class, 'employer')]"
            ]
            for selector in company_selectors:
                try:
                    company_elem = article.find_element(By.XPATH, selector)
                    if company_elem.is_displayed():
                        company = company_elem.text.strip()
                        if company:
                            break
                except:
                    continue
                
            if not company:
                company = "Unknown Company"
            
            # Extract location
            location = None
            location_selectors = [
                ".//span[contains(@class, 'location')]",
                ".//div[contains(@class, 'location')]",
                ".//span[contains(text(), 'Egypt')]"
            ]
            for selector in location_selectors:
                try:
                    location_elem = article.find_element(By.XPATH, selector)
                    if location_elem.is_displayed():
                        location = location_elem.text.strip()
                        if location:
                            break
                except:
                    continue
                
            if not location:
                location = "Egypt"
            
            # Get URL from the job link
            url = None
            try:
                link = article.find_element(By.CSS_SELECTOR, "a[data-test='job-link']")
                url = link.get_attribute('href')
            except:
                try:
                    # Backup: try to find any link that might be the job link
                    links = article.find_elements(By.TAG_NAME, "a")
                    for link in links:
                        href = link.get_attribute('href')
                        if href and 'job' in href.lower():
                            url = href
                            break
                except:
                    pass
                
            if not url:
                print("Could not find job URL")
                return None
            
            # Build job info dictionary
            job_info = {
                'title': title,
                'company': company,
                'location': location,
                'url': url
            }
            
            print(f"Successfully extracted basic info: {title} at {company}")
            return job_info
            
        except Exception as e:
            print(f"Error extracting card details: {str(e)}")
            return None

    def get_job_details(self, job_card):
        """Extract details from a job card with retry logic"""
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                print("\nAttempting to extract job details...")
                self.debug_element(job_card, "Job Card")
                
                # First, try to get the title without clicking
                title_element = None
                title_selectors = [
                    "a[data-test='job-link']",
                    "a.jobLink",
                    ".job-title",
                    "h2.jobTitle",
                    "[data-test='job-title']"
                ]
                
                for selector in title_selectors:
                    try:
                        title_element = job_card.find_element(By.CSS_SELECTOR, selector)
                        if title_element.is_displayed():
                            break
                    except:
                        continue
                
                if not title_element:
                    raise Exception("Could not find title element")
                
                # Try to click the title element
                try:
                    title_element.click()
                except:
                    self.driver.execute_script("arguments[0].click();", title_element)
                
                time.sleep(2)
                self.handle_popups()
                
                # Get basic job information
                job_info = {
                    'title': title_element.text,
                    'url': title_element.get_attribute('href') or self.driver.current_url
                }
                
                # Get company name
                company_selectors = [
                    "[data-test='employer-name']",
                    ".employer-name",
                    ".jobEmployer",
                    ".companyName"
                ]
                
                for selector in company_selectors:
                    try:
                        company = job_card.find_element(By.CSS_SELECTOR, selector)
                        if company.is_displayed():
                            job_info['company'] = company.text
                            break
                    except:
                        continue
                
                if 'company' not in job_info:
                    print("Warning: Could not find company name")
                    job_info['company'] = "Unknown Company"
                
                # Get location
                location_selectors = [
                    "[data-test='location']",
                    ".location",
                    ".job-location",
                    ".loc"
                ]
                
                for selector in location_selectors:
                    try:
                        location = job_card.find_element(By.CSS_SELECTOR, selector)
                        if location.is_displayed():
                            job_info['location'] = location.text
                            break
                    except:
                        continue
                
                if 'location' not in job_info:
                    print("Warning: Could not find location")
                    job_info['location'] = "Egypt"
                
                # Wait for and get job description
                description_selectors = [
                    ".jobDescriptionContent",
                    "#JobDesc",
                    ".job-description",
                    "[data-test='job-description']"
                ]
                
                description = None
                for selector in description_selectors:
                    try:
                        desc_element = self.wait_for_element(selector)
                        if desc_element:
                            description = desc_element.text
                            break
                    except:
                        continue
                
                if not description:
                    raise Exception("Could not find job description")
                
                # Add additional information
                job_info.update({
                    'source': 'Glassdoor',
                    'jobType': 'Internship',
                    'postedDate': datetime.now().strftime("%Y-%m-%d"),
                    'detailed_requirements': description,
                    'skills': self.extract_skills(description),
                    'isPaid': any(word in description.lower() for word in ['paid', 'salary', 'compensation', 'stipend']),
                    'isRemote': any(word in description.lower() for word in ['remote', 'work from home', 'wfh', 'virtual'])
                })
                
                print(f"Successfully extracted job details for: {job_info['title']}")
                return job_info
                
            except Exception as e:
                print(f"Error extracting job details (attempt {retry_count + 1}): {str(e)}")
                retry_count += 1
                time.sleep(random.uniform(1, 2))
                self.handle_popups()
                
        return None

    def scrape_jobs(self, num_pages=10):
        all_jobs = []
        
        try:
            for page in range(1, num_pages + 1):
                print(f"\nProcessing page {page}...")
                url = f"{self.base_url}?p={page}"
                self.driver.get(url)
                time.sleep(random.uniform(3, 5))
                
                self.handle_popups()
                
                # Wait for the job list to load
                print("Waiting for job list to load...")
                try:
                    job_list = self.wait.until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, "[data-test='jobsList']"))
                    )
                    print("Job list found")
                except Exception as e:
                    print(f"Could not find job list: {str(e)}")
                    # Save page source for debugging
                    with open(f"debug_page_{page}.html", "w", encoding="utf-8") as f:
                        f.write(self.driver.page_source)
                    print(f"Saved page source to debug_page_{page}.html")
                    continue
                
                # Try to find job cards using multiple methods
                job_cards = []
                
                # Method 1: Direct children of job list
                try:
                    cards = job_list.find_elements(By.XPATH, "./li")
                    if cards:
                        print(f"Found {len(cards)} cards using direct li elements")
                        job_cards = cards
                except Exception as e:
                    print(f"Error finding cards using direct li elements: {str(e)}")
                
                # Method 2: Specific class names
                if not job_cards:
                    try:
                        cards = self.driver.find_elements(By.CSS_SELECTOR, "li.react-job-listing")
                        if cards:
                            print(f"Found {len(cards)} cards using react-job-listing class")
                            job_cards = cards
                    except Exception as e:
                        print(f"Error finding cards using react-job-listing class: {str(e)}")
                
                # Method 3: Article elements
                if not job_cards:
                    try:
                        cards = self.driver.find_elements(By.TAG_NAME, "article")
                        if cards:
                            print(f"Found {len(cards)} cards using article elements")
                            job_cards = cards
                    except Exception as e:
                        print(f"Error finding cards using article elements: {str(e)}")
                
                if not job_cards:
                    print("No job cards found using any method")
                    continue
                
                # Process each job card
                for index, card in enumerate(job_cards, 1):
                    try:
                        print(f"\nProcessing job card {index}/{len(job_cards)}")
                        self.debug_element(card, f"Job Card {index}")
                        
                        job_info = self.get_job_details_from_card(card)
                        if job_info:
                            # Get full description
                            print(f"Getting full description for {job_info['title']}")
                            description = self.get_job_description(job_info['url'])
                            
                            if description:
                                # Add additional information
                                job_info.update({
                                    'source': 'Glassdoor',
                                    'jobType': 'Internship',
                                    'postedDate': datetime.now().strftime("%Y-%m-%d"),
                                    'detailed_requirements': description,
                                    'skills': self.extract_skills(description),
                                    'isPaid': any(word in description.lower() for word in ['paid', 'salary', 'compensation', 'stipend']),
                                    'isRemote': any(word in description.lower() for word in ['remote', 'work from home', 'wfh', 'virtual'])
                                })
                                
                                all_jobs.append(job_info)
                                print(f"Successfully added job: {job_info['title']} at {job_info['company']}")
                            else:
                                print("Could not get job description")
                    
                    except Exception as e:
                        print(f"Error processing job card {index}: {str(e)}")
                        continue
                
                print(f"Completed page {page}")
                time.sleep(random.uniform(3, 5))
                
        except Exception as e:
            print(f"Error during scraping: {str(e)}")
            
        return all_jobs

    def extract_skills(self, description):
        tech_skills = [
            'python', 'java', 'javascript', 'react', 'angular', 'vue', 'node',
            'sql', 'mysql', 'postgresql', 'mongodb', 'aws', 'azure', 'git',
            'docker', 'kubernetes', 'html', 'css', 'php', 'c++', 'c#',
            'machine learning', 'ai', 'data science', 'flutter', 'swift',
            'kotlin', 'android', 'ios', 'spring', 'django', 'flask',
            '.net', 'typescript', 'ruby', 'rust', 'golang', 'scala',
            'hadoop', 'spark', 'tableau', 'power bi', 'excel', 'r',
            'tensorflow', 'pytorch', 'opencv', 'unity', 'unreal'
        ]
        
        found_skills = []
        description_lower = description.lower()
        
        for skill in tech_skills:
            if skill in description_lower:
                found_skills.append(skill)
                
        return found_skills

    def save_jobs(self, jobs, filename='assets/glassdoor_internships.json'):
        try:
            # Create assets directory if it doesn't exist
            os.makedirs('assets', exist_ok=True)
            
            # Load existing jobs if file exists
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    existing_jobs = json.load(f)
            except (FileNotFoundError, json.JSONDecodeError):
                existing_jobs = []

            # Add new jobs to existing ones, avoiding duplicates based on URL
            existing_urls = {job['url'] for job in existing_jobs}
            new_jobs = [job for job in jobs if job['url'] not in existing_urls]
            all_jobs = existing_jobs + new_jobs

            # Save all jobs
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(all_jobs, f, indent=2, ensure_ascii=False)

            print(f"Saved {len(new_jobs)} new jobs. Total jobs: {len(all_jobs)}")

        except Exception as e:
            print(f"Error saving jobs: {str(e)}")

    def run(self, num_pages=10):
        try:
            jobs = self.scrape_jobs(num_pages)
            self.save_jobs(jobs)
        finally:
            self.driver.quit()

if __name__ == "__main__":
    scraper = GlassdoorScraper()
    scraper.run() 