**How to analyse the results**

This document &#39;how\_to\_analyse\_results&#39; ([LittoSim\_model](https://github.com/LittoSim/LittoSim_model/commits/LittoDev)/[docs](https://github.com/LittoSim/LittoSim_model/commits/LittoDev/Rscripts)/) presents the results of both scripts R post-processing : leader\_data.R and manager\_data.R

For more information [https://github.com/LittoSim/LittoSim\_model/blob/LittoDev/README.md](https://github.com/LittoSim/LittoSim_model/blob/LittoDev/README.md)

- **Environment parameters**

The both scripts have been tested with versions 3.5.3 and 3.6.3

Know your version

_Print(version)_

&quot;Utf-8&quot; coding to support French language characters

_options(encoding = &quot;utf-8&quot;)_

IMPORTANT : The list of names &#39;coms&#39; (short names) and &#39;insees&#39; (INSEE codes of the municipalities) must be in the same order that configuration files &#39;study\_area.conf&#39; in Gama : MAP\_DIST\_SNAMES

| _Overflow\_coast-v_ | _Overflow\_coast-h_ |
| --- | --- |
| ![](RackMultipart20201026-4-wj5x4e_html_6c0f267ec0f00e1e.png) | ![](RackMultipart20201026-4-wj5x4e_html_fe49ccb9055b1dee.png)
 |
| _Estuary-coast_ | _Cliff\_coast_ |
| ![](RackMultipart20201026-4-wj5x4e_html_34884471bed5c8a8.png) | ![](RackMultipart20201026-4-wj5x4e_html_3a411a65a1499663.png) |

- **Define your workspace**

_setwd( &quot;C:/LittoSIM\_GEN\_formation/blabla/&quot;)_

- Copy the directory &#39;manager\_data-X.xxxxxx&#39; to the server in your worskpace and define it

_MANAGER\_DATA \&lt;- &quot;manager\_data-1.587376322512E12/&quot;_

_LEADER\_DATA \&lt;- &quot;leader\_data-1.587376442452E12/&quot;_

- _The directory manager content 3 directories_
  - _Csvs :one file by district_
  - _Flood\_results : corresponding to the simulations launched during the game_
  - _Shapes : &#39;Land\_Use\_x&#39; and &#39;Coastal\_Defense\_x&#39; for each__of play_

- The origin files shapefiles of archetype model are in this directory :

e.g. [\\includes\cliff\_coast\shapefiles](/%5C%5Cincludes%5Ccliff_coast%5Cshapefiles)

- **Manage graph with ggplot2**

- If the names of axis are too long : add &#39;_\n&#39;_

_scale\_x\_discrete(label=c(&quot;Zones\n environementales __**\n** _ _protégées&quot;,&quot;Zones à risques_ _ **\n**__ (PPR)&quot;,&quot;Total&quot;),_

- With package &#39;ggplot&#39;, a graph by action use _position\_stack_ (absolute values) and a graph by pourcent : _position\_fill_

- Mapping variable values to colors, Change the color actions : Example : Densification action : black to grey

_command\_to\_colors\&lt;c(&quot;1&quot;=&quot;yellow&quot;,&quot;2&quot;=&quot;orange&quot;,&quot;4&quot;=&quot;darkgreen&quot;,&quot;4.5&quot;=&quot;yellowgreen&quot;,&quot;5&quot;=&quot;darkred&quot;,&quot;6&quot;=&quot;red&quot;,&quot;7&quot;=&quot;beige&quot;,&quot;8&quot;=&quot;darkblue&quot;,&quot;26&quot;=&quot;lightsalmon&quot;,&quot;28&quot;=&quot;darkkhaki&quot;,&quot;29&quot;=&quot;lightsalmon&quot;,&quot;30&quot;=&quot;darkorchid&quot;,&quot;31&quot;=&quot;magenta&quot;,&quot;32&quot;=&quot;blue&quot;,&quot;44&quot;=&quot;pink&quot;,&quot;311&quot;=&quot; __**grey**__&quot;)_

_LittoSIM_