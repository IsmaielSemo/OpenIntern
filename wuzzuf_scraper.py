import json
import time
import random
import logging
from typing import List, Dict, Optional
import argparse
from urllib.parse import quote_plus
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import re
import socket
import dns.resolver
import requests
import os
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class WuzzufScraper:
    def __init__(self):
        # Using search URL for internships in Egypt with tech focus
        self.base_url = "https://wuzzuf.net/search/jobs/?q=internship+software+developer+engineer+programming+computer+science&a=navbg"
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
        max_retries = 3
        for attempt in range(max_retries):
            try:
                self.driver.get(job_url)
                time.sleep(random.uniform(2, 3))
                
                # Wait for job details to load and get description
                description = ""
                for selector in [".css-1uobp1k", ".job-description", ".css-1t5f0fr"]:
                    try:
                        element = self.wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, selector)))
                        description = element.text
                        break
                    except:
                        continue
                
                if not description:
                    description = "No description available"
                
                # Get company name
                company = "Unknown Company"
                for selector in [".css-17s97q8", ".css-u1gwks a"]:
                    try:
                        element = self.driver.find_element(By.CSS_SELECTOR, selector)
                        company = element.text
                        break
                    except:
                        continue
                
                # Get location
                location = "Egypt"
                for selector in [".css-9geu3q", ".css-md7z0h"]:
                    try:
                        element = self.driver.find_element(By.CSS_SELECTOR, selector)
                        location = element.text
                        break
                    except:
                        continue
                
                # Get posting date
                date = datetime.now().strftime("%Y-%m-%d")
                for selector in [".css-182mrdn", ".css-do6t5g"]:
                    try:
                        element = self.driver.find_element(By.CSS_SELECTOR, selector)
                        date = element.text
                        break
                    except:
                        continue
                
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
                print(f"Error getting job details (attempt {attempt + 1}/{max_retries}): {str(e)}")
                if attempt < max_retries - 1:
                    time.sleep(random.uniform(2, 4))
                    continue
                return None

    def get_job_cards(self):
        """Get all job cards from the current page"""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                # Wait for any job card to appear first
                self.wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, ".css-1gatmva")))
                time.sleep(1)  # Short delay to ensure all cards load
                
                # Try different selectors for job cards
                for selector in [".css-1gatmva", ".css-1q7g5aa"]:
                    cards = self.driver.find_elements(By.CSS_SELECTOR, selector)
                    if cards:
                        return cards
                
                return []
                
            except Exception as e:
                print(f"Error getting job cards (attempt {attempt + 1}/{max_retries}): {str(e)}")
                if attempt < max_retries - 1:
                    time.sleep(random.uniform(2, 4))
                    continue
                return []

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
            'qa engineer', 'quality assurance', 'test automation', 'sdet',
            
            # Must include internship-related terms
            'intern', 'internship', 'trainee', 'training program'
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

    def scrape_jobs(self, num_pages=10):
        all_jobs = []
        
        try:
            for page in range(1, num_pages + 1):
                print(f"\nProcessing page {page}...")
                url = f"{self.base_url}&start={15 * (page - 1)}"
                
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
                        
                        # Get title and URL directly from the current card
                        try:
                            title_element = card.find_element(By.CSS_SELECTOR, "h2")
                            title = title_element.text
                            
                            link_element = card.find_element(By.CSS_SELECTOR, "h2 a")
                            job_url = link_element.get_attribute('href')
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
                                    'source': 'Wuzzuf',
                                    'jobType': 'Tech Internship',
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

    def save_jobs(self, jobs, filename='assets/wuzzuf_internships.json'):
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

def main():
    parser = argparse.ArgumentParser(description='Wuzzuf.net Job Scraper')
    parser.add_argument('--query', default='internship', help='Search query')
    parser.add_argument('--pages', type=int, default=5, help='Number of pages to scrape')
    parser.add_argument('--headless', action='store_true', help='Run in headless mode')
    parser.add_argument('--output', default='tech_internships.json', help='Output file path')
    parser.add_argument('--timeout', type=int, default=30, help='Page load timeout in seconds')
    
    args = parser.parse_args()
    
    scraper = WuzzufScraper()
    try:
        jobs = scraper.scrape_jobs(args.pages)
        
        # Save results to JSON file
        scraper.save_jobs(jobs, args.output)
            
        logger.info(f"Scraped {len(jobs)} tech/engineering internships and saved to {args.output}")
    except Exception as e:
        logger.error(f"Error during scraping: {str(e)}")

if __name__ == "__main__":
    main() 