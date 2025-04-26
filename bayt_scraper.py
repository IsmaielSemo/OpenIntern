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

class BaytScraper:
    def __init__(self):
        # Using search URL for internships in Egypt
        self.base_url = "https://www.bayt.com/en/egypt/jobs/?q=intern+OR+internship&jobTypes=2"
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
        chrome_options.add_argument('--window-size=1920,1080')
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.wait = WebDriverWait(self.driver, 10)

    def extract_skills(self, description):
        """Extract technical skills from job description"""
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

    def get_job_details(self, job_url):
        """Get detailed job information from the job page"""
        try:
            self.driver.get(job_url)
            time.sleep(random.uniform(2, 3))
            
            # Wait for job details to load
            self.wait.until(EC.presence_of_element_located((By.CLASS_NAME, "job-description")))
            
            # Extract job description
            description = self.driver.find_element(By.CLASS_NAME, "job-description").text
            
            # Extract company name
            company = self.driver.find_element(By.CSS_SELECTOR, "a.is-company").text
            
            # Extract location
            location = self.driver.find_element(By.CSS_SELECTOR, "span.is-location").text
            
            # Extract posting date
            try:
                date = self.driver.find_element(By.CSS_SELECTOR, "time.is-posted-date").get_attribute("datetime")
            except:
                date = datetime.now().strftime("%Y-%m-%d")
            
            return {
                'company': company,
                'location': location,
                'postedDate': date,
                'detailed_requirements': description,
                'skills': self.extract_skills(description),
                'isPaid': any(word in description.lower() for word in ['paid', 'salary', 'compensation', 'stipend']),
                'isRemote': any(word in description.lower() for word in ['remote', 'work from home', 'wfh', 'virtual'])
            }
            
        except Exception as e:
            print(f"Error getting job details: {str(e)}")
            return None

    def scrape_jobs(self, num_pages=10):
        all_jobs = []
        
        try:
            for page in range(1, num_pages + 1):
                print(f"\nProcessing page {page}...")
                url = f"{self.base_url}&page={page}"
                self.driver.get(url)
                time.sleep(random.uniform(2, 3))
                
                # Wait for job listings to load
                job_cards = self.wait.until(
                    EC.presence_of_all_elements_located((By.CSS_SELECTOR, "li.has-pointer-d"))
                )
                
                print(f"Found {len(job_cards)} job cards")
                
                # Process each job card
                for index, card in enumerate(job_cards, 1):
                    try:
                        print(f"\nProcessing job {index}/{len(job_cards)}")
                        
                        # Get basic information from the card
                        title = card.find_element(By.CSS_SELECTOR, "h2.m0").text
                        
                        # Only process tech-related positions
                        if not any(keyword in title.lower() for keyword in [
                            'software', 'developer', 'engineer', 'tech', 'it', 'data',
                            'web', 'mobile', 'frontend', 'backend', 'fullstack', 'programming'
                        ]):
                            continue
                        
                        # Get job URL
                        job_link = card.find_element(By.CSS_SELECTOR, "h2.m0 a")
                        job_url = job_link.get_attribute('href')
                        
                        # Get detailed job information
                        print(f"Getting details for: {title}")
                        job_details = self.get_job_details(job_url)
                        
                        if job_details:
                            # Combine basic and detailed information
                            job_info = {
                                'title': title,
                                'url': job_url,
                                'source': 'Bayt',
                                'jobType': 'Internship',
                                **job_details
                            }
                            
                            all_jobs.append(job_info)
                            print(f"Added job: {title} at {job_details['company']}")
                            
                    except Exception as e:
                        print(f"Error processing job card {index}: {str(e)}")
                        continue
                
                print(f"Completed page {page}")
                time.sleep(random.uniform(2, 3))
                
        except Exception as e:
            print(f"Error during scraping: {str(e)}")
            
        return all_jobs

    def save_jobs(self, jobs, filename='assets/bayt_internships.json'):
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
    scraper = BaytScraper()
    scraper.run() 