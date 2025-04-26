# Advanced Indeed.com Scraper

This is an advanced web scraper for Indeed.com that can extract job listings with features like rotating user agents, proxy support, and comprehensive error handling.

## Features

- Rotating user agents to avoid detection
- Proxy support for IP rotation
- Comprehensive error handling and retry logic
- Detailed logging
- Saves results to JSON file

## Requirements

- Python 3.7+
- Required packages listed in `requirements.txt`

## Installation

1. Clone this repository
2. Install the required packages:
   ```
   pip install -r requirements.txt
   ```

## Usage

1. Create a file named `proxies.txt` with your proxy list (one proxy per line in the format `http://username:password@host:port`)
2. Run the scraper:
   ```
   python advanced_indeed_scraper.py
   ```

## Configuration

You can modify the following parameters in the script:
- `MAX_RETRIES`: Maximum number of retry attempts for failed requests
- `RETRY_DELAY`: Delay between retry attempts in seconds
- `OUTPUT_FILE`: Path to save the results

## Output

The scraper will save the results to `indeed_internships.json` in the following format:
```json
[
  {
    "title": "Job Title",
    "company": "Company Name",
    "location": "Job Location",
    "salary": "Salary Range",
    "description": "Job Description",
    "url": "Job URL"
  },
  ...
]
```

## Error Handling

The scraper includes comprehensive error handling for:
- Network errors
- Rate limiting
- Invalid responses
- Parsing errors

All errors are logged to the console with appropriate error messages.

## Disclaimer

This scraper is for educational purposes only. Please respect Indeed.com's terms of service and robots.txt when using this tool.

## License

MIT
