import json
import time
import random
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from selenium.webdriver.chrome.options import Options
from datetime import datetime
import re
from dotenv import load_dotenv

class LinkedInScraper:
    def __init__(self):
        load_dotenv()  # Load environment variables
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        ]
        self.base_url = "https://www.linkedin.com"
        self.setup_driver()
        
    def setup_driver(self):
        chrome_options = Options()
        chrome_options.add_argument(f'user-agent={random.choice(self.user_agents)}')
        chrome_options.add_argument('--headless=new')  # Updated headless mode
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--enable-javascript')
        # Add additional options to handle WebGL warnings
        chrome_options.add_argument('--ignore-certificate-errors')
        chrome_options.add_argument('--enable-unsafe-swiftshader')
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.wait = WebDriverWait(self.driver, 10)
        
    def login(self):
        try:
            print("Attempting to log in to LinkedIn...")
            self.driver.get("https://www.linkedin.com/login")
            time.sleep(2)

            # Get credentials from environment variables
            email = os.getenv('LINKEDIN_EMAIL')
            password = os.getenv('LINKEDIN_PASSWORD')

            if not email or not password:
                raise Exception("LinkedIn credentials not found in environment variables")

            # Find and fill email field
            email_field = self.wait.until(
                EC.presence_of_element_located((By.ID, "username"))
            )
            email_field.send_keys(email)

            # Find and fill password field
            password_field = self.driver.find_element(By.ID, "password")
            password_field.send_keys(password)

            # Click login button
            login_button = self.driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            login_button.click()

            # Wait for login to complete
            time.sleep(5)
            
            print("Successfully logged in to LinkedIn")
            return True

        except Exception as e:
            print(f"Failed to log in: {str(e)}")
            return False

    def get_search_url(self, page=1):
        params = {
            'keywords': 'tech intern OR technology internship OR software intern OR software engineer intern',
            'location': 'Egypt',
            'f_E': '1',  # Entry level/Internship
            'f_JT': 'I',  # Internship
            'start': (page - 1) * 25,  # LinkedIn uses 25 jobs per page
            'sortBy': 'DD'  # Sort by most recent
        }
        query = '&'.join([f'{k}={v}' for k, v in params.items()])
        return f"{self.base_url}/jobs/search/?{query}"

    def extract_skills(self, description):
        # Common tech skills to look for
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

    def extract_job_details(self, job_url):
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                self.driver.get(job_url)
                time.sleep(random.uniform(2, 4))

                # Wait for job details to load
                description = self.wait.until(
                    EC.presence_of_element_located((By.CLASS_NAME, "show-more-less-html__markup"))
                ).text

                # Extract all the required information
                job_info = {
                    'url': job_url,
                    'detailed_requirements': description,
                    'skills': self.extract_skills(description),
                    'additional_skills': [],  # Will be filled with secondary skills
                    'isPaid': any(word in description.lower() for word in ['paid', 'salary', 'compensation', 'stipend', 'egp', 'usd']),
                    'isRemote': any(word in description.lower() for word in ['remote', 'work from home', 'wfh', 'virtual'])
                }

                # Extract experience requirement
                exp_pattern = r'(\d+[-\s]?\d*\s*(?:year|yr)s?|no experience|fresh graduate|entry level)'
                exp_match = re.search(exp_pattern, description.lower())
                job_info['experience_required'] = exp_match.group(0) if exp_match else 'Not specified'

                # Extract education requirement
                edu_pattern = r'(bachelor|master|phd|degree|student|undergraduate)'
                edu_match = re.search(edu_pattern, description.lower())
                job_info['education_required'] = edu_match.group(0) if edu_match else 'Not specified'

                return job_info

            except Exception as e:
                print(f"Error extracting job details (attempt {retry_count + 1}): {str(e)}")
                retry_count += 1
                time.sleep(random.uniform(2, 4))
                
                if retry_count == max_retries:
                    return None

    def scrape_jobs(self, num_pages=10):
        if not self.login():
            print("Failed to log in. Cannot proceed with scraping.")
            return []

        all_jobs = []
        
        for page in range(1, num_pages + 1):
            try:
                url = self.get_search_url(page)
                self.driver.get(url)
                time.sleep(random.uniform(3, 5))

                # Wait for job cards to load
                job_cards = self.wait.until(
                    EC.presence_of_all_elements_located((By.CSS_SELECTOR, ".job-card-container"))
                )

                for card in job_cards:
                    try:
                        # Extract basic information from the card
                        title = card.find_element(By.CSS_SELECTOR, ".job-card-list__title").text
                        company = card.find_element(By.CSS_SELECTOR, ".job-card-container__company-name").text
                        location = card.find_element(By.CSS_SELECTOR, ".job-card-container__metadata-item").text
                        posted_date = card.find_element(By.CSS_SELECTOR, "time").get_attribute("datetime")
                        job_url = card.find_element(By.CSS_SELECTOR, ".job-card-list__title").get_attribute("href")

                        # Get detailed job information
                        job_details = self.extract_job_details(job_url)
                        
                        if job_details:
                            job_info = {
                                'title': title,
                                'company': company,
                                'location': location,
                                'jobType': 'Internship',
                                'postedDate': posted_date,
                                **job_details
                            }
                            all_jobs.append(job_info)
                            print(f"Scraped job: {title} at {company}")

                    except NoSuchElementException as e:
                        print(f"Error extracting card details: {str(e)}")
                        continue

                print(f"Completed page {page}")
                time.sleep(random.uniform(3, 5))

            except Exception as e:
                print(f"Error on page {page}: {str(e)}")
                continue

        return all_jobs

    def save_jobs(self, jobs, filename='assets/internships.json'):
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
    scraper = LinkedInScraper()
    scraper.run() 