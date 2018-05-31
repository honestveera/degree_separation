# Degree Separation

With cinema going global these days, every one of the [A-Z]ollywoods are now connected. Use the wealth of data available at [Moviebuff](http://www.moviebuff.com) to see how. 

### Liraries Used:
1.OptionParse - Ruby Command Line Interface

2.json - Parse Json Data. 

3.net/http - Http Request handling [Example: https://data.moviebuff.com/amitabh-bachchan] 

4.zlib - Compress and Decompress Data

### RUBY program that behaves the following way:
```
$ ruby small_degree_separation.rb --help
     Usage: small_degree_separation.rb [options]
    -s, --source                     Person 1 Name
    -d, --destination                Person 2 Name
    -h, --help                       Display this screen
    
$ ruby small_degree_separation.rb -s amitabh-bachchan -d obert-de-niro  

Total no.of.request sent: 1
Total time taken (in ms) : 1

Degrees of Separation: 3

Movie: The Great Gatsby
Supporting Actor: Amitabh Bachchan
Actor: Leonardo DiCaprio

Movie: The Wolf of Wall Street
Actor: Leonardo DiCaprio
Director: Martin Scorsese

Movie: Taxi Driver
Director: Martin Scorsese
Actor: Robert De Niro
```
