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

class JobzellaScraper:
    def __init__(self):
        # Using search URL for tech internships in Egypt
        self.base_url = "https://www.jobzella.com/en/jobs?keywords=internship+software+developer+engineer&country=Egypt"
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
        chrome_options.add_argument('--log-level=3')  # Suppress WebGL warnings
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.wait = WebDriverWait(self.driver, 10)

    def is_tech_internship(self, title, description):
        """Check if the job is a tech internship based on title and description"""
        tech_keywords = {
            # Development roles
            'software', 'developer', 'web', 'frontend', 'front end', 'front-end',
            'backend', 'back end', 'back-end', 'full stack', 'fullstack',
            'mobile', 'ios', 'android', 'flutter', 'react native',
            
            # Engineering roles
            'engineer', 'engineering', 'devops', 'reliability', 'systems',
            'cloud', 'infrastructure', 'platform', 'security',
            
            # Data roles
            'data', 'machine learning', 'ml', 'ai', 'artificial intelligence',
            'deep learning', 'nlp', 'data science', 'analytics',
            
            # Tech domains
            'computer science', 'programming', 'coding', 'software development',
            'application development', 'tech', 'it', 'information technology',
            
            # Quality roles
            'qa engineer', 'quality assurance', 'test automation', 'sdet'
        }
        
        # Convert to lower case for comparison
        title_lower = title.lower()
        description_lower = description.lower()
        
        # Check if it's an internship
        is_internship = any(word in title_lower or word in description_lower 
                          for word in ['intern', 'internship', 'trainee', 'training program'])
        
        # Check if it's tech-related
        is_tech = any(keyword in title_lower or keyword in description_lower 
                     for keyword in tech_keywords)
        
        # Additional checks for tech skills in description
        has_tech_skills = any(skill in description_lower for skill in [
            'python', 'java', 'javascript', 'typescript', 'c++', 'c#',
            'php', 'ruby', 'swift', 'kotlin', 'rust', 'golang',
            'sql', 'mysql', 'postgresql', 'mongodb', 'database',
            'react', 'angular', 'vue', 'node', 'express', 'django',
            'flask', 'spring', 'asp.net', '.net core',
            'aws', 'azure', 'gcp', 'cloud computing',
            'docker', 'kubernetes', 'jenkins', 'ci/cd',
            'git', 'github', 'gitlab', 'bitbucket',
            'rest api', 'graphql', 'microservices',
            'html', 'css', 'sass', 'less', 'bootstrap',
            'junit', 'pytest', 'selenium', 'cypress'
        ])
        
        return is_internship and (is_tech or has_tech_skills)

    def get_job_details(self, job_url):
        """Get detailed job information from the job page"""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                self.driver.get(job_url)
                time.sleep(random.uniform(2, 3))
                
                # Wait for job details to load
                self.wait.until(EC.presence_of_element_located((By.CLASS_NAME, "job-description")))
                
                # Get job description
                description = self.driver.find_element(By.CLASS_NAME, "job-description").text
                
                # Get company name
                try:
                    company = self.driver.find_element(By.CLASS_NAME, "company-name").text
                except:
                    company = "Unknown Company"
                
                # Get location
                try:
                    location = self.driver.find_element(By.CLASS_NAME, "job-location").text
                except:
                    location = "Egypt"
                
                # Get posting date
                try:
                    date = self.driver.find_element(By.CLASS_NAME, "job-date").text
                except:
                    date = datetime.now().strftime("%Y-%m-%d")
                
                # Get job type
                try:
                    job_type = self.driver.find_element(By.CLASS_NAME, "job-type").text
                except:
                    job_type = "Not specified"
                
                # Get salary if available
                try:
                    salary = self.driver.find_element(By.CLASS_NAME, "job-salary").text
                    is_paid = True
                except:
                    salary = "Not specified"
                    is_paid = "paid" in description.lower() or "salary" in description.lower()
                
                return {
                    'company': company,
                    'location': location,
                    'postedDate': date,
                    'jobType': job_type,
                    'salary': salary,
                    'detailed_requirements': description,
                    'skills': self.extract_skills(description),
                    'isPaid': is_paid,
                    'isRemote': any(word in description.lower() for word in ['remote', 'work from home', 'wfh', 'virtual'])
                }
                
            except Exception as e:
                print(f"Error getting job details (attempt {attempt + 1}/{max_retries}): {str(e)}")
                if attempt < max_retries - 1:
                    time.sleep(random.uniform(2, 4))
                    continue
                return None

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

    def get_job_cards(self):
        """Get all job cards from the current page"""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                # Wait for job cards to appear
                self.wait.until(EC.presence_of_element_located((By.CLASS_NAME, "job-card")))
                time.sleep(1)  # Short delay to ensure all cards load
                
                # Get all job cards
                return self.driver.find_elements(By.CLASS_NAME, "job-card")
                
            except Exception as e:
                print(f"Error getting job cards (attempt {attempt + 1}/{max_retries}): {str(e)}")
                if attempt < max_retries - 1:
                    time.sleep(random.uniform(2, 4))
                    continue
                return []

    def scrape_jobs(self, num_pages=10):
        all_jobs = []
        
        try:
            for page in range(1, num_pages + 1):
                print(f"\nProcessing page {page}...")
                url = f"{self.base_url}&page={page}"
                
                # Load the page with retries
                max_retries = 3
                for attempt in range(max_retries):
                    try:
                        self.driver.get(url)
                        break
                    except Exception as e:
                        if attempt < max_retries - 1:
                            print(f"Error loading page (attempt {attempt + 1}/{max_retries}): {str(e)}")
                            time.sleep(random.uniform(2, 4))
                            continue
                        raise
                
                time.sleep(random.uniform(2, 3))
                
                # Get job cards
                job_cards = self.get_job_cards()
                print(f"Found {len(job_cards)} job cards")
                
                # Process each job card
                for index, card in enumerate(job_cards, 1):
                    try:
                        print(f"\nProcessing job {index}/{len(job_cards)}")
                        
                        # Get title and URL
                        try:
                            title_element = card.find_element(By.CLASS_NAME, "job-title")
                            title = title_element.text
                            job_url = title_element.get_attribute('href')
                        except Exception as e:
                            print(f"Error extracting basic job info: {str(e)}")
                            continue
                        
                        print(f"Getting details for: {title}")
                        job_details = self.get_job_details(job_url)
                        
                        if job_details:
                            # Check if it's a tech internship
                            if self.is_tech_internship(title, job_details['detailed_requirements']):
                                # Combine basic and detailed information
                                job_info = {
                                    'title': title,
                                    'url': job_url,
                                    'source': 'Jobzella',
                                    **job_details
                                }
                                
                                all_jobs.append(job_info)
                                print(f"Added tech internship: {title} at {job_details['company']}")
                            else:
                                print(f"Skipping non-tech internship: {title}")
                            
                    except Exception as e:
                        print(f"Error processing job card {index}: {str(e)}")
                        continue
                
                print(f"Completed page {page}")
                time.sleep(random.uniform(2, 3))
                
        except Exception as e:
            print(f"Error during scraping: {str(e)}")
            
        return all_jobs

    def save_jobs(self, jobs, filename='assets/jobzella_internships.json'):
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
    scraper = JobzellaScraper()
    scraper.run() 