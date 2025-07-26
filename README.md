# Open Science Blogs Archive

This is a repository containing open science blogs that were especially active before, during and after what is now known as the replication crisis in psychology. 
The discussions on these blogs were important for scholarly communication during the early replication crisis, but are at risk of disappearing. Some blogs are only available through the wayback machine, and the knowledge of who contributed to discussions in these years is disappearing. For these reasons, I decided to archive these blogs. 

# Shiny App and data file

If you just want to explore the archive, download the repository, and in RStudio run the 'app.R' Shiny app. This will allow you to browse the full archive, search for keywords, or pick a random blog post, or explore what was happening on this date some years ago.
If you want to use the data for analyses, then load blog_data.rds. It has the following columns: 
- file: Local file name
- title: Blog title
- date: Date extracted from blog post
- content: Text only version of blogs
- content_html: HTML versions of blogs
- url: URL to blog post (might not be online)
- date_clean: Cleaned date
- id: A unique id number, used as prefix for blog images to prevent duplicate names, and to identify individual blog posts. Assigned based on chronological order. 
- author: Blog author
- html_content_local: Version of html content pointing to local images, can be rendered without internet access.

# Archive contents 

In total 3530 blogs by the following 52 individuals or collectives have been archived (up to approximately July 2025):

100% CI (Ruben Arslan, Malte Elson, Julia Rohrer, Anne Scheel)
Alex Holcombe  
Alison Ledgerwood  
Ana Todorovic
Åse Innes-Ker  
Bobbie Spellman  
Brent Donnellan  
Brent Roberts  
Chris Chambers  
Cogtales (Christina Bergmann, Sho Tsuji)
Daniel Lakens  
Dan Simons  
Data Colada (Leif Nelson, Uri Simonsohn, Joe Simmons)
David Funder  
Dorothy Bishop  
Etienne Lebel  
Felix Schönbrodt  
Hannah Watkins  
Ian Hussey  
Jake Westfall   
James Heathers   
Jason Mitchell    
Jeff Rouder  
Jim Grange  
Joe Hilgard  
John Bargh  
John Sakaluk  
Katie Corker  
Lorne Campbell  
Michael Inzlicht  
Moin Syed  
Nick Brown  
Nicole Janz  
Open Science Collaboration  
Patrick Langford  
Patrick Forscher  
PsychFileDrawer (Hal Pashler, Bobbie Spellman, Alex Holcombe)  
Richard Morey  
Rich Lucas  
Ryne Sherman  
Roger Giner-Sorolla  
Rolf Zwaan  
Sam Schwarzkopf  
Sanjay Srivastava  
Simine Vazire  
Simone Schnall  
Statistical Modeling (Andrew Gelman, Jessica Hullman)  
Tal Yarkoni  
Tim van der Zee  
Uli Schimmack  
Will Gervais  
Xenia Schmalz  

# Creation of blog archive

Blogs have been downloaded using HTtrack. https://www.httrack.com/ 
Scan rules:
-* +*thehardestscience.com/* -*thehardestscience.com/*?share=*
The folder structure contains more files than we need to archive, so I have automatically deleted:
- The folder hts-cache, wordpress.com, public-api.wordpress.com.
- The files hts-log.txt, cookies.txt, backblue.gif, fade.gif.
- All folders nested in other folders called ‘feed’ were deleted. In blogspot these are called ‘feeds’. 
- All ‘index.html’ files that appear alongside folders with numbers (e.g., 04, 05) can be deleted. 
- All folders with the word “%3frelatedposts%3d1” were deleted. 
- Blogspot folders have many ‘search’ htmls: searchaf7d.html were deleted. 
- Blogspot folders have a ‘js’ folder. 
- Blogspot will have multiple versions of the same file, for example: top-notch-speakers.html and top-notch-speakers7b6b.html. It is always 4 numbers and letters after it. These double files are deleted. 
- Blogspot also has an index.html and multiple named html files. If there are both index and html files in a folder, the index.html file can be deleted. 

Some sites were already gone, and I got those by using https://github.com/hartator/wayback-machine-downloader after installing Ruby (https://rubyinstaller.org/downloads/) 
Then I needed https://github.com/hartator/wayback-machine-downloader/issues/307
Manually grab the version from https://github.com/ShiftaDeband/wayback-machine-downloader, unzip, and replace files in C:\Ruby34-x64\lib\ruby\gems\3.4.0\gems\wayback_machine_downloader-2.3.1\lib and bin folders.
Then in Windows Powershell you can provide the command: 
wayback_machine_downloader http://traitstate.wordpress.com --to 20210413205110  
Detailed instructions: 
1. gem install wayback_machine_downloader
2. Unzip the package wayback-machine-downloader-feature-httpGet.zip
3. Copy the folder wayback_machine_downloader in the lib folder into folder C:\Ruby34-x64\lib
4. Next replace the file 'wayback_machine_downloader' inside bin folder into the bin folder of C:\Ruby34-x64\bin
5. Use the code wayback_machine_downloader https://website_link/ --to timestamp to download

The Statistical Modeling blog does not allow for automated downloads, and individual blog posts were downloaded by searching for a range of keywords such as 'replication'. As posts appear almost daily, and there are many more posts on this blog than on all other blogs combined, and many are not related to the replication crisis, this targeted approach was used in order to not overwhelm the blog post database with posts from one blog.
For Lee Jussim's and James Heathers' blogs I similarly went through all blog posts and downloaded those most relevant to the replication crisis. 

After these steps, there was some reproducible cleaning of data files, using the script clean_downloaded_osf_blogs.R in the folder processing_blogs_code. This was followed by non-reproducible and extensive manual cleaning of irrelevant files. Some files were recreated as html files from other archival sources. 
The script process_openscience_blogs.R was used to retrieve the content, both in raw texts as in html, blog dates and titles. If blogs only included a month and year, but not the date of publishing, they were set to the first of the month.
The cleaned files were stored in a folder 'blogs_clean'. This 1.53 GB folder can be downloaded from Pcloud: https://e.pcloud.link/publink/show?code=kZBg4EZ29xfWMaizAY4tBehNHlru7M3KlJy. I will also archive the uncleaned 14.6 GB folder with all downloaded blogs there in the future. 

All blogs were read into R from a local and stored as blog_data.rds. This only includes text.
In the app folder there is a Shiny app that reads in a special version of the database. This loads all images locally. The download_or_copy_images.R script was used to get all images either from httrack downloaded blogs, or download them if blogs were still online. A special version of the html code is created where all links to images are changed so they point to the local images in the subfolder www/images. 

There will be bugs, missing images, badly formatted text, and missing blogs, but this is as much as I have the time to do for now. 
