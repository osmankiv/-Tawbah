#  Tawbah|توبة
### Intelligent AI System for Lowering the Gaze on Windows

**Tawbah** is a professional Windows-based application that helps young people **lower their gaze** by intelligently filtering web images using Artificial Intelligence.  
The system selectively **blurs or hides images of females only**, while keeping the rest of the webpage fully visible and functional.

##  Vision

In a world full of visual distractions, **Tawbah** was created to support youth in maintaining focus, purity of sight, and ethical browsing — without isolating them from the internet or blocking useful content.


##  Overview

Unlike traditional content blockers that shut down entire websites, **Tawbah** works at the image level:

- Helps users practice *غضّ البصر*  
-  Preserves website usability  
-  Blocks only what needs to be blocked  
-  Encourages self-discipline, not isolation  

The application runs locally on Windows and uses AI-powered computer vision to analyze and filter images in real time.



##  Key Features

- Intelligent selective image filtering  
- Female-only image detection  
- Real-time processing  
- No website blocking  
- Works with all modern browsers  
- Fully local & privacy-respecting  
- Multiple filtering modes:
  - Blur images
  - Hide images
  - Replace images with neutral placeholders  

---

##  How It Works

**Tawbah** operates as a **local proxy** between the browser and the internet:

1. Web images are intercepted before rendering  
2. Images are analyzed using AI models  
3. Human presence and gender are detected  
4. If a female is detected, the image is filtered  
5. The rest of the webpage loads normally  

This allows a smooth and respectful browsing experience.



##  Technologies Used

- **Python**
- **OpenCV**
- **YOLOv8**
- **mitmproxy**
- **AI Gender Classification Models**
- **Windows OS**



##  System Requirements

- Windows 10 or later  
- Python 3.9+  
- Any modern browser (Chrome, Edge, Firefox)  
- Minimum 4GB RAM (8GB recommended)

---

##  Installation

###  Clone the repository
## bash
git clone https://github.com/osmankiv/tawbah.git
cd tawbah
## Install dependencies

Bash
pip install -r requirements.txt
## Run Tawbah

Bash
mitmproxy -s tawbah_filter.py
## Configure browser proxy


Address: 127.0.0.1
Port:    8080
## Install mitmproxy certificate (once)
Visit:


http://mitm.it
# Configuration
You can customize:
Detection sensitivity
Blur strength
Filtering mode
Gender confidence threshold
All options are available in config.py.
# Privacy & Ethics
All process،ing is local
No images are saved
No external servers or APIs
No tracking or monitoring
Tawbah is designed to support moral discipline, not surveillance.
# Use Cases
Personal self-discipline
Youth guidance tools
Religious and conservative environments
Educational institutions
Safe browsing setups
# Limitations
AI accuracy depends on image clarity
Some edge cases may bypass detection
Initial proxy setup is required
# Future Plans
Simple graphical user interface (GUI)
Automatic startup with Windows
Improved gender classification accuracy
Mobile companion version
User profiles and schedules
# Contribution
Contributions are welcome.
Feel free to fork the project, open issues, or submit pull requests.
# License
MIT License
# Purpose
“قُلْ لِلْمُؤْمِنِينَ يَغُضُّوا مِنْ أَبْصَارِهِمْ”
— سورة النور
Tawbah exists to help, not to force —
a companion on the path of self-control and awareness.
#Author
Developed with sincerity
to help youth walk a cleaner digital path.
