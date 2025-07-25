# Open Science Blogs Archive

This is a repository containing open science blogs that were especially active during what is now known as the replication crisis. 
The discussions on these blogs were important for scholarly communication during the early replication crisis, but are at risk of disappearing. SOme blogs are no longer available online, and the knowledge of who contributed to discussions in these years is also disappearing. For these reasons, I decided to archive these blogs. 

Blogs by the following 51 individuals or collectives have been archived (up to June 2025):

100% CI (Ruben Arslan, Malte Elson, Julia Rohrer, Anne Scheel)
Alexander Etz  
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
Sam Schwarzkopf  
Nick Brown  
Open Science Collaboration
Patrick Langford  
Patrick Forscher
PsychFileDrawer (Hal Pashler, Bobbie Spellman, Alex Holcombe)
Richard Morey  
Rich Lucas  
Ryne Sherman  
Roger Giner-Sorolla  
Rolf Zwaan  
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
•	The folder hts-cache, wordpress.com, public-api.wordpress.com.
•	The files hts-log.txt, cookies.txt, backblue.gif, fade.gif.
•	All folders nested in other folders called ‘feed’ were deleted. In blogspot these are called ‘feeds’. 
•	All ‘index.html’ files that appear alongside folders with numbers (e.g., 04, 05) can be deleted. 
•	All folders with the word “%3frelatedposts%3d1” were deleted. 
•	Blogspot folders have many ‘search’ htmls: searchaf7d.html were deleted. 
•	Blogspot folders have a ‘js’ folder. 
•	Blogspot will have multiple versions of the same file, for example: top-notch-speakers.html and top-notch-speakers7b6b.html. It is always 4 numbers and letters after it. These double files are deleted. 
•	Blogspot also has an index.html and multiple named html files. If there are both index and html files in a folder, the index.html file can be deleted. 

Some sites were already gone, and I got those from https://github.com/hartator/wayback-machine-downloader after installing Ruby (https://rubyinstaller.org/downloads/) 
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

After these steps, there was non-reproducible and extensive manual cleaning of irrelevant files. Some files were recreated as html files from other archival sources. A script was used to retrieve blog dates and titles. If blogs only included a month and year, but not the date of publishing, they were set to the first of the month.  

All blogs were read into R and stored as blog_data.rds. This only includes text, and not the pictures. A future plan is to also archive all pictures. 