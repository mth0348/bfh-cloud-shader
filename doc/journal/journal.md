# Meeting protocol 

## \#01: February 18, 2020
### Formal and technical questions
* Use of LaTeX for project documentation? -> ok.
* Interests expressed in volumetric rendering, 3D noise cube generation, signed distance functions (SDF) and surface normal estimation algorithms. Advanced topic to look in to: subsurface scattering.

### Meeting discussion
Gitlab repository [cloud-shader](https://gitlab.ti.bfh.ch/cpvr-students/cloud-shader) should be used as storage for all project files.

**Documentation guidelines**
* The document is supposed to be rather technical. There is no need for general introduction to what a shader is, for example.

**Tasks**
* Read published papers about real-time cloud rendering
* Compare popular techniques and methods

Next meeting is scheduled for March 2, 2020 at 3pm.

**Time log**

| Task | time spent |
|----|---|
| Setup of latex work environment | 4h |
| Initial draft of specification document | 4h |
| Research on existing papers about cloud rendering | 1h |
|||

&nbsp;

&nbsp;
#
## \#02: March 2, 2020
### Formal and technical questions
* Meeting protocol okay in form of markdown?
* Keep project requirement specification separate from main document?
* When is the deadline of the project submission?

### Meeting discussion

**Tasks**
* Rename the repository from "cloud-shader" to "2020-cloud-shader".
* The meeting of April 13th, 2020 will be moved to **April 14th, 2020 at 3:30 pm**.
* Finish final draft of specification.tex by March 13th, 2020 and send it to the tutor.


**Remarks about the specification.tex**
* In "Scope of Work", add subsection "Vision". This should contain a short description of what this project could be followed with / long-term goals.
* Add section "Requirements" containing subsections
    * "Research requirements": what to research?
    * "Develop requirements": Define what prototypes should be implemented. Each prototype should derive from a requirement, which again derives from a goal. Also "Evaluation of libs" could be a requirement.
* Add section "Testing"
* In "Results", add subsection "Presentation". This should contain information about the presentation occuring on the second last friday of the term, during school time.
* Add more images. At least in "Vision", add an image showing how I would like the prototypes to look like.
* Add milestones to section "Planning"

~~Next meeting is scheduled for March 16, 2020 at 3pm.~~ (moved due to conficting schedule)  
Next meeting is scheduled for March 17, 2020 at 2:30pm.


**Time log**

| Task | time spent |
|----|---|
| Updated document in regards of the discussed points | 10h |
|||

&nbsp;

&nbsp;

#
## \#03: March 17, 2020
*(meeting was moved from March 16th to March 17th)*

### Formal and technical topics
* Begin main paper
    * Working on achieving research requirements / research goals

### Meeting discussion

**Remarks about the specification.tex**
* Add version to title page.
* In chapter 2.5, add "LaTeX documentation" to "Visual Studio Code", so it becomes more clear that the documentation is actually made in Visual Studio Code.
* Chapter 2.5 should be renamed to "Used Software and Tools".
* Rework chapter 3 to the following structure:
    * 3: Project Management
        * 3.1 Schedule
        * 3.2 Project organization
            * Meetings, every 2 weeks, video conference
        * 3.3 Results

* In "Schedule", add "documentation" to the Gantt chart.
* In "Testing"
    * Add "Visual comparison with photographic reference".
    * Add "Performance Testing"
        * Influence on performance of parameters / variables 
* Add rendering techniques to the glossary and shortly explain them.

**Until end of the week: Send definitive version of req. specification to tutor.**

**Time log**

| Task | time spent |
|----|---|
| Updated document in regards of the discussed points | 4h |
| Started paper.tex | 4h |
| Added first research results about clouds | 8h |
|||

&nbsp;

&nbsp;

#
## \#04: March 30, 2020
### Formal and technical topics
* Reference self-made images? - No.
* Abbreviations for CT and MRI? - Maybe add abbrev. in brackets.
* When prototyping results?, when code snippets?, when pseudo-code? - Maybe small real code, else pseudo-code.
* Volumetric rendering = ray casting



### Meeting discussion
**Remarks about the paper.tex**
* Add literature sources (pdfs, blogs, unity docs) in a separate section, next to "References".
* Glossary records should not be too short. Don't be afraid to write one or two sentences.
* Add Target audiance to chapter 1
    * maybe add "3d computer graphics" knowledge as a requirement to understand this document
* Add "voxel" and "scalar field" and "vector field" to the glossary
* Add major chapters
    * Project management, time management, retroperspectively written at the end of the project
        * reasoning why D.1 and D.3 are the same
    * Prototypes
    * Results / evaluation
* List code in "Attachments" if the code is too large.

**Notes**
* Voxel = Volume Element
* scalar field has scalar values
* vector field has vector values


**Time log**
| Task | time spent |
|----|---|
| Added research results about volumetric rendering | 4h |
| Added research results about ray marching | 4h |
| Added research results sphere tracing | 6h |
| Added research results shadow casting | 6h |
| Added research results ambient occlusion | 4h |
|||
&nbsp;

&nbsp;

#
## \#05: April 14th, 2020
*(This meeting was moved to April 14th, 2020 at 2:30 pm.)*

### Formal and technical topics
* Next up: Begin work with noise generation
    * How to achieve randomness in shaders
    * Commonly known noise algorithms
        * Worley
        * Perlin
        * Voronoi
    * 3D noise cube
* In 2D random, the dot() product is chosen arbitrarily?
    * https://thebookofshaders.com/10/

### Meeting discussions
* shadow casting is usually done from light source
        * note that this is also possible
* "Constructive solid geometry" additionally to "Solid primitive operators"
* Random 2D
    * citation/reference is ok

**Time log**
| Task | time spent |
|----|---|
| Added research results about noise generation | 4h |
| Added research results about perlin noise | 8h |
|||

## \#06: April 27th, 2020
* init() in unity script, seed setzen 
* built-in unity perlin noise ausprobieren
* kapitel "gradient", bild von 3d gradient as well (3.1.5.1)
* end of chapter, hinweis das noise in 3d verwendet wird.

**Time log**
| Task | time spent |
|----|---|
| Added research results about Voronoi noise | 6h |
| prototyping | 4h |
|||

&nbsp;

&nbsp;

#
## \#07: May 11th, 2020
### Formal and technical topics
\-

### Meeting discussions
* Performance optimization: Stop ray march when cloud density hits 1.0
* Reality check? What is most realistic, how to compare to real-life?


**Time log**
| Task | time spent |
|----|---|
| prototyping | 8h |
| prototyping | 8h |
| prototyping | 8h |
| Added prototype results | 8h |
| Added prototype results | 4h |
|||
&nbsp;

&nbsp;

#
## \#08: May 25th, 2020
### Formal and technical topics
* Last meeting before presentation. Any tips?
    * Technical depth

* Chapter "project management" - Content?
    * How faithful to schedule?
    * What went wrong?
    * Future work?

* Open ToDos:
    * (--) How does built-in Mathf.PerlinNoise() work?
    * (✔) Better reality check?
    * (✔) 3D gradient in section 3.1.5.1

### Meeting discussions
* Presentation
    * Audience is mixed (CPVR1 and CPVR3 students)
    * Algorithms are good to show, code is maybe too technical
    * Demonstration is key
    * Time: +/- 10min
    * Send finished presentation file to Prof for review before June 5th
* Optimizations
    * Instead of screen-space position for light forwarding, maybe just compare angle (like in Phong)
    * Other measureable realism: evaluation by meteorologist
    * Ask Prof Hudritsch for a method to measure similarity of two pictures
* Future work
    * Maybe expose only meteorological parameters to Editor and adjust internal variables according to them
        * like height, temparature, moistness


* ToDo
    * (✔) Add "Sebstian Lague" as a reference
    * (✔) Document tricks and tuning of parameters and shader files (Code is documented)
    * (✔) 3D gradient in section 3.1.5.1
    * (✔) Abstract
    * (✔) GANs
    * (✔) Instead of screen-space position for light forwarding, maybe just compare angle (like in Phong)
    * (✔) Other measureable realism: evaluation by meteorologist
    * (✔) Ask Prof Hudritsch for a method to measure similarity of two pictures

**Time log**
| Task | time spent |
|----|---|
| Added project managemeent section | 4h |
| Finalized document | 4h |
|||
&nbsp;

&nbsp;

#
## \#09: Final June 8th, 2020
### Formal and technical topics
\-

### Meeting discussions
\-

* genus einführen bevor genera
* figure 4: bodenaufnahme
AAA -major publisher
comments for first use of params

3.4 reword first sentence


constants: variables in purple are constants, konkrete grösse erst bei prototypen ermittelt
(bei erstem code listing)

Figure 19 weglassen

Soft shadows rework algorithm so that k=0 means hard shadows, and k = 100 means soft shadows

4.1 "and rigid code environment" -> "determinstic execution environment
0

Due to more development time available

moist -> humidity




*Project fazit* ()
viel gelernt,
schedule eingehalten,
corona egal gewesen,

*Consclusion and critical discussion* (end of prototype)
Technische conclusion?
Was haben wir realisiert? (vorallem finaler prototype)
vergleich mit anderen state-of-the-art?
schwachstellen?
\nocites dorthin schieben


HDR colors added -> colors
