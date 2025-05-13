import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
app.use(cors());
app.use(express.json());

const OPENROUTER_API_KEY = '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';
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

function buildPrompt({ jobTitle, company, requiredSkills, detailedRequirements, mode }) {
// ... existing code ...
if (mode === 'cover_letter') {
    return `
Generate a professional cover letter for the following internship:

Job Title: ${jobTitle}
Company: ${company}
Required Skills: ${requiredSkills.join(', ')}
Detailed Requirements: ${detailedRequirements}

Return ONLY valid JSON in this format:
{
  "coverLetter": "the cover letter text"
}
Do not include any explanation or text outside the JSON object.
`;
  } else if (mode === 'courses') {
    return `
Suggest 3-5 online courses (with links) that would help a candidate prepare for the following internship:

Job Title: ${jobTitle}
Company: ${company}
Required Skills: ${requiredSkills.join(', ')}
Detailed Requirements: ${detailedRequirements}

Return ONLY valid JSON in this format:
{
  "recommendedCourses": [
    {"name": "Course Name", "url": "https://..."},
    {"name": "Course Name", "url": "https://..."}
  ]
}
Each course must have a "name" and a "url" field. If you don't know the course URL, use an empty string for the url field. Do not include any explanation or text outside the JSON object.
`;
  } else if (mode === 'questions') {
    return `
List 5-7 problem solving or technical interview questions that may be asked for the following internship:

Job Title: ${jobTitle}
Company: ${company}
Required Skills: ${requiredSkills.join(', ')}
Detailed Requirements: ${detailedRequirements}

Return ONLY valid JSON in this format:
{
  "questions": [
    "Question 1?",
    "Question 2?",
    "Question 3?"
  ]
}
Do not include any explanation or text outside the JSON object.
`;
  } else {
    // Default to cover letter
    return `
Generate a professional cover letter for the following internship:

Job Title: ${jobTitle}
Company: ${company}
Required Skills: ${requiredSkills.join(', ')}
Detailed Requirements: ${detailedRequirements}

Return ONLY valid JSON in this format:
{
  "coverLetter": "the cover letter text"
}
Do not include any explanation or text outside the JSON object.
`;
  }
}

app.post('/generate', async (req, res) => {
  try {
    const { jobTitle, company, requiredSkills, detailedRequirements, mode } = req.body;
    const prompt = buildPrompt({ jobTitle, company, requiredSkills, detailedRequirements, mode });

    const response = await fetch(OPENROUTER_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'deepseek/deepseek-chat-v3-0324:free',
        messages: [
          { role: 'system', content: 'You are a helpful AI assistant that returns only valid JSON as instructed.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1000
      })
    });

    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.toString() });
  }
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));