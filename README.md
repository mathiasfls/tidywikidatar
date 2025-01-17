
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidywikidatar

<!-- badges: start -->

[![R-CMD-check](https://github.com/EDJNet/tidywikidatar/workflows/R-CMD-check/badge.svg)](https://github.com/EDJNet/tidywikidatar/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidywikidatar)](https://CRAN.R-project.org/package=tidywikidatar)
[![CRAN
Downloads](https://cranlogs.r-pkg.org/badges/tidywikidatar)](http://cran.r-project.org/package=tidywikidatar)
<!-- badges: end -->

The goal of `tidywikidatar` is to facilitate interaction with Wikidata:

-   all responses are transformed into data frames or simple character
    vectors
-   it is easy to enable efficient caching in a local sqlite database
    (integration with other databases is also available)

If you want to benefit of the wealth of information stored by Wikidata,
but you do not like SPARQL queries and nested lists, then you may find
`tidywikidatar` useful. If you prefer working with nested lists and
SPARQL queries, or if you plan to build more complex queries, then you
should probably use [`WikidataR`](https://github.com/TS404/WikidataR) or
Wikimedia’s own
[`WikidataQueryServiceR`](https://github.com/wikimedia/WikidataQueryServiceR)
(under the hood, `tidywikidatar` is largely based on those packages).

## Installation

You can install the released version of `tidywikidatar` from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("tidywikidatar")
```

For the latest fixes and improvements, you can install the development
version from [Github](https://github.com/EDJNet/tidywikidatar) with:

``` r
# install.packages("remotes")
remotes::install_github("EDJNet/tidywikidatar")
```

## Limitations and known issues

`tidywikidatar` strives to strike a balance between ease of use and full
access to information available on Wikidata. This means that, for
examples, dates are returned as simple text strings, without
accompanying details such as calendar (e.g. Julian or Gregorian) and
precision (e.g. precise just to the level of century). Some amounts are
returned as numeric strings, without the accompanying unit of
measurement. The user should be aware of such issues in their own use
cases, and consider using other packages if such matters are determinant
for them. Recent versions of `tidywikidatar` include a dedicated
function to get such details, `tw_get_property_with_details()`, but it
does not currently cache results.

`tidywikidatar` is most useful in particular for the exploratory
analysis of relatively small numbers of wikidata items (dozens or
hundreds), but becomes quickly less efficient when asking for many
properties or thousands of items. Functions will take their time, but
will eventually complete. Some performance improvements may come with
future versions of `tidywikidatar`, but for larger batches of data
(large number of items/many properties), well formed queries will remain
more efficient.

### Known issues

-   `tw_search()` always returns label and description in English (to be
    fixed)

## Use cases and publicly available examples

These articles or repository demonstrate some use cases for
`tidywikidatar`:

-   [Finding out more about Members of the European Parliament with
    Wikidata](https://medium.com/european-data-journalism-network/a-new-r-package-for-exploring-the-wealth-of-information-stored-by-wikidata-fe85e82b6440)
-   [Retrieve details about Olympics 2020 medalists via Wikipedia and
    Wikidata](https://edjnet.github.io/olympics2020nuts/) / see also
    [this interactive map based on
    Wikidata](https://edjnet.github.io/olympics2020nuts/medalists_map.html)
-   [Which among the busiest air routes in Europe could actually be
    travelled by land?](https://edjnet.github.io/european_routes/)
-   [Finding gendered street
    names](https://medium.com/european-data-journalism-network/finding-gendered-street-names-a-step-by-step-walkthrough-with-r-7608c2d36a77)

While the code used there may not be fully compatible or be the most
efficient with the latest version of Wikidata, they still provide a
useful term of reference.

## Before you start

This package assumes some familiarity with basic Wikidata concepts. For
reference, see [the introduction on the official
website](https://www.wikidata.org/wiki/Wikidata:Introduction).

At the most basic, you should know that every item in Wikidata has an id
(it always starts with a Q, something like `Q123456`). Each item is
described by properties (they always start with a P, something like
`P1234`).

So for example, if I am interested in the anthropologist Margaret Mead,
I will search her name on Wikidata and discover that she is
[`Q180099`](https://www.wikidata.org/wiki/Q180099). She is described by
many properties. For example, she is “an instance of”
([P31](https://www.wikidata.org/wiki/Property:P31))
“[Q5](https://www.wikidata.org/wiki/Q180099)”, which means “human”. Her
“sex or gender” ([P21](https://www.wikidata.org/wiki/Property:P21)) is
“[Q180099](https://www.wikidata.org/wiki/Q6581072)”, which means,
female. By “occupation”
([P106](https://www.wikidata.org/wiki/Property:P106)), she was
“[Q36180](https://www.wikidata.org/wiki/Q36180)”,
“[Q4773904](https://www.wikidata.org/wiki/Q4773904)”, and
“[Q674426](https://www.wikidata.org/wiki/Q674426)”, which means, a
writer, an anthropologist, and a curator. And so forth.

As you’ll see, many queries return just another wikidata id, and if you
want to know what that means, you’ll need to ask for what that id stands
for.

## How to use

`tidywikidatar` makes it easy to cache locally responses (both searches
and details about specific items) in a sqlite database to reduce load on
Wikidata’s servers and increase processing speed. These sqlite databases
are by default stored in the current working directory under a `tw_data`
folder. It may be useful to store them in a folder where they can be
retrieved easily even when working on different projects, but this is
obviously a matter of personal taste. You can enable caching for the
current session with `tw_enable_cache()`, set the cache folder to be
used throughout a session with `tw_set_cache_folder()`, and set the
language used by all functions (if not set, it defaults to English). The
first lines of a script using `tidywikidatar` would often look like
this:

``` r
library("tidywikidatar")
tw_enable_cache()
tw_set_cache_folder(path = fs::path(fs::path_home_r(), "R", "tw_data"))
tw_set_language(language = "en")
tw_create_cache_folder(ask = FALSE)
```

This also means that you can re-run code when offline, as data are
downloaded from Wikidata’s server only at first run (that is, unless you
set `cache = FALSE` or `overwrite_cache = TRUE` when calling the
respective functions, or disable caching for the current session with
`tw_disable_cache()`).

## Finding details about something

Most `tidywikidatar` functions are built around the idea that you know
what you are looking for, and just want to get what Wikidata knows about
it, assuming the preferred choice would be among the top results.

Let’s take this again from the beginning. As I mentioned, I am
interested in Margaret Mead, the famous pioneer anthropologist author of
“Coming of Age in Samoa”. This seems quite straightforward but there are
actually a number of things that are returned by searching for “Margaret
Mead” that are not the woman herself.

``` r
tw_search(search = "Margaret Mead")
#> # A tibble: 10 × 3
#>    id        label                               description                    
#>    <chr>     <chr>                               <chr>                          
#>  1 Q180099   Margaret Mead                       American anthropologist        
#>  2 Q81015029 Margaret mead                       scientific article published o…
#>  3 Q66701460 Margaret Mead                       scientific article published o…
#>  4 Q85724626 Mead & Bateson                      business organisation          
#>  5 Q96077616 Margaret Meadows                    (1718-1781)                    
#>  6 Q76238541 Margaret Meadowe                    Peerage person ID=628312       
#>  7 Q75506638 Margaret Meadows                    Peerage person ID=183057       
#>  8 Q75812372 Margaret Meade-Waldo                (died 1954)                    
#>  9 Q6759717  Margaret Mead Film Festival         annual film festival held in N…
#> 10 Q55897055 Margaret Mead and Samoa: Coming of… <NA>
```

If I am running through a list of strings, and, for example, I am
actually interested in the most famous person by that name, I can filter
result by property, using the standard form. If, for example, I want
only the first result that is associated with “an instance of” (P31) -
“human” (Q5), I can run:

``` r
tw_search(search = "Margaret Mead") %>%
  tw_filter_first(p = "P31", q = "Q5")
#> # A tibble: 1 × 3
#>   id      label         description            
#>   <chr>   <chr>         <chr>                  
#> 1 Q180099 Margaret Mead American anthropologist
```

and, as expected, I get a single output: my beloved Margaret Mead.

Where was she born? I can ask directly for P19, place of birth:

``` r
tw_get_property(id = "Q180099", p = "P19")
#> # A tibble: 1 × 3
#>   id      property value
#>   <chr>   <chr>    <chr>
#> 1 Q180099 P19      Q1345
```

which, as expected, will give me another wikidata id. But what does,
“Q1345” stand for? I should ask for its label.

``` r
tw_get_label(id = "Q1345")
#> [1] "Philadelphia"
```

Alright, I know where Philadelphia, but if it was a smaller place,
perhaps I’d need to ask in which country it is located. So I would ask
for the correspondent property, P17.

``` r
tw_get_property(id = "Q1345", p = "P17")
#> # A tibble: 1 × 3
#>   id    property value
#>   <chr> <chr>    <chr>
#> 1 Q1345 P17      Q30
```

Oh, no, another Wikidata id! That’s the way it works… let’s ask for its
label:

``` r
tw_get_label(id = "Q30")
#> [1] "United States of America"
```

It takes some time to get used, but I suppose you get the gist of it.

You can also pipe all of the above, like this:

``` r
tw_search(search = "Margaret Mead") %>% # search for Margeret Mead
  tw_filter_first(p = "P31", q = "Q5") %>% # keep only the first result that is of a human
  tw_get_property(p = "P19") %>% # ask for the place of birth
  dplyr::pull(value) %>% # take its result and
  tw_get_property(p = "P17") %>% # ask for the country where that place of birth is located
  tw_get_label() # ask what that id stands for
#> [1] "Philadelphia"
```

And here we are, we know in which country Margaret Mead was born.

The procedure above may seem a bit convoluted, but it is actually quite
representative of how Wikidata stores information.

As you would expect, such functions can also be combined, for example,
like this:

``` r
get_bio <- function(id, language = "en") {
  tibble::tibble(
    label = tw_get_label(id = id, language = language),
    description = tw_get_description(id = id, language = language),
    year_of_birth = tw_get_property(id = id, p = "P569") %>%
      dplyr::pull(value) %>%
      head(1) %>%
      lubridate::ymd_hms() %>%
      lubridate::year(),
    year_of_death = tw_get_property(id = id, p = "P570") %>%
      dplyr::pull(value) %>%
      head(1) %>%
      lubridate::ymd_hms() %>%
      lubridate::year()
  )
}

tw_search(search = "Margaret Mead") %>%
  tw_filter_first(p = "P31", q = "Q5") %>%
  get_bio()
#> # A tibble: 1 × 4
#>   label         description             year_of_birth year_of_death
#>   <chr>         <chr>                           <dbl>         <dbl>
#> 1 Margaret Mead American anthropologist          1901          1978
```

I can of course get the response in languages other than English, as
long as those are available on Wikidata.

``` r
tw_search(search = "Margaret Mead") %>%
  tw_filter_first(p = "P31", q = "Q5") %>%
  get_bio(language = "it")
#> # A tibble: 1 × 4
#>   label         description              year_of_birth year_of_death
#>   <chr>         <chr>                            <dbl>         <dbl>
#> 1 Margaret Mead antropologa statunitense          1901          1978
```

## Serial operations

More examples regarding serial operations, and streamlined queries over
long lists of ids will be available in a dedicated vignette in a future
version.

In the meantime, let us just say that if we wanted to have a list of all
the “awards received”
([P166](https://www.wikidata.org/wiki/Property:P166)) by Margaret Mead,
and fellow anthropologists and folklorists Ruth Benedict and Zora Neale
Hurston, we can achieve that in a single call:

``` r
tw_get_property(
  id = c("Q180099", "Q228822", "Q220480"),
  p = "P166",
  language = "en"
) 
#> # A tibble: 14 × 3
#>    id      property value    
#>    <chr>   <chr>    <chr>    
#>  1 Q180099 P166     Q17144   
#>  2 Q180099 P166     Q782022  
#>  3 Q180099 P166     Q8017107 
#>  4 Q180099 P166     Q1967852 
#>  5 Q180099 P166     Q52382875
#>  6 Q228822 P166     Q1967852 
#>  7 Q228822 P166     Q52382875
#>  8 Q228822 P166     Q752297  
#>  9 Q220480 P166     Q1316544 
#> 10 Q220480 P166     Q1967852 
#> 11 Q220480 P166     Q5461701 
#> 12 Q220480 P166     Q5461189 
#> 13 Q220480 P166     Q4765305 
#> 14 Q220480 P166     Q1316544
```

Again, Wikidata ids. We can of course get their relative labels using
the functions outlined above, but `tidywikidatar` has a convenience
function - `tw_label()` that will achieve what you want in most such
cases.

``` r
tw_get_property(
  id = c("Q180099", "Q228822", "Q220480"),
  p = "P166",
  language = "en"
) %>% 
  tw_label()
#> # A tibble: 14 × 3
#>    id                 property       value                                      
#>    <chr>              <chr>          <chr>                                      
#>  1 Margaret Mead      award received Presidential Medal of Freedom              
#>  2 Margaret Mead      award received Kalinga Prize                              
#>  3 Margaret Mead      award received William Procter Prize for Scientific Achie…
#>  4 Margaret Mead      award received National Women's Hall of Fame              
#>  5 Margaret Mead      award received AAAS Fellow                                
#>  6 Ruth Benedict      award received National Women's Hall of Fame              
#>  7 Ruth Benedict      award received AAAS Fellow                                
#>  8 Ruth Benedict      award received Doctor of Philosophy                       
#>  9 Zora Neale Hurston award received Guggenheim Fellowship                      
#> 10 Zora Neale Hurston award received National Women's Hall of Fame              
#> 11 Zora Neale Hurston award received Florida Women's Hall of Fame               
#> 12 Zora Neale Hurston award received Florida Artists Hall of Fame               
#> 13 Zora Neale Hurston award received Anisfield-Wolf Book Awards                 
#> 14 Zora Neale Hurston award received Guggenheim Fellowship
```

## Piped operations

Using the pipe (`%>%`) when working with Wikidata is often not
straightforward, due to the fact that a given property may have an
unspecified number of values. `tidywikidatar` offers dedicated functions
to work with the pipe more consistently, in particular
`tw_get_property_same_length()`.

One main distinction to keep in mind in this context is that for some
properties we really just expect to have a single value, and we are
happy to dismiss other values that may be present, while in other cases
we expect and want to retain more values.

For example, some Wikidata items have two reported dates of birth for a
single individual, possibly due to disagreements among historians about
the actual date of birth of the given person. If this is not
specifically the issue we are interested it, we may well be want just to
keep the first reported date of birth and dismiss the others. In other
cases, we probably want to retain all properties, and process them
further in subsequent steps of the pipe.

Let’s look at some of these issues with an example.

The anthropologist Franz Boas
([Q76857](https://www.wikidata.org/wiki/Q76857)) had many influential
doctoral students ([P185](https://www.wikidata.org/wiki/Property:P185)),
including the above-mentioned Margaret Mead. Who where the others? And
when and where were they born? We expect the answer to this latter
questions to be unique, and we may be fine with discarding other values
that may be recorded in Wikidata.

``` r
library("dplyr", warn.conflicts = FALSE)
library("tidyr")
students <-
  tw_get_property(id = "Q76857", p = "P185") %>%  # who were Boas' doctoral students?
  transmute(student_label = tw_get_label(value), # get their name
                   student_id = value) # and keep their id


students %>%  
  mutate(date_of_birth = tw_get_property_same_length(id = student_id,
                                                     p = "P569", # property for date of birth
                                                     only_first = TRUE)) %>%
  # we don't care about possible multiple values on when they were born
  mutate(place_of_birth = tw_get_property_same_length(id = student_id,
                                                     p = "P19", # property for place of birth
                                                     only_first = TRUE) %>% 
           tw_get_label())
#> # A tibble: 20 × 4
#>    student_label                 student_id date_of_birth         place_of_birth
#>    <chr>                         <chr>      <chr>                 <chr>         
#>  1 Ruth Benedict                 Q228822    +1887-06-05T00:00:00Z New York City 
#>  2 Edward Sapir                  Q191095    +1884-01-26T00:00:00Z Lębork        
#>  3 Alexander Francis Chamberlain Q32178     +1865-01-01T00:00:00Z Kenninghall   
#>  4 Manuel Gamio                  Q2602445   +1883-01-01T00:00:00Z Mexico City   
#>  5 Alexander Goldenweiser        Q1396805   +1880-01-29T00:00:00Z Kyiv          
#>  6 Irving Goldman                Q6074597   +1911-09-02T00:00:00Z <NA>          
#>  7 Melville J. Herskovits        Q711288    +1895-09-10T00:00:00Z Bellefontaine 
#>  8 George Herzog                 Q15454430  +1901-12-11T00:00:00Z Budapest      
#>  9 E. Adamson Hoebel             Q5321710   +1906-01-01T00:00:00Z Madison       
#> 10 Melville Jacobs               Q6813885   +1902-07-03T00:00:00Z New York City 
#> 11 William Jones                 Q8013732   +1871-00-00T00:00:00Z <NA>          
#> 12 Alfred L. Kroeber             Q311538    +1876-06-11T00:00:00Z Hoboken       
#> 13 Alexander Lesser              Q4719396   +1902-01-01T00:00:00Z <NA>          
#> 14 Robert Lowie                  Q44968     +1883-06-12T00:00:00Z Vienna        
#> 15 Margaret Mead                 Q180099    +1901-12-16T00:00:00Z Philadelphia  
#> 16 Paul Radin                    Q557443    +1883-04-02T00:00:00Z Łódź          
#> 17 Gladys Reichard               Q15998733  +1893-07-17T00:00:00Z Bangor        
#> 18 Leslie Spier                  Q6531152   +1893-12-13T00:00:00Z <NA>          
#> 19 Ruth Sawtell Wallis           Q7383203   +1895-03-15T00:00:00Z Springfield   
#> 20 Edward A. Kennard             Q58050409  +1907-10-24T00:00:00Z <NA>
```

In other cases, however, we do expect multiple valid values. For
example, we expect them to have a single place and date of birth, but
quite possibly to have worked in different locations at different points
in their career.

Here is how we may want to go if we want, for example, to create a map
of all the universities where one of Franz Boas’ doctoral students has
worked. We get the id of all the places where they have worked, check if
they are universities or not, and then get the coordinates for the given
institutions.

``` r
students %>% 
  mutate(worked_at_id = tw_get_property_same_length(id = student_id,
                                                     p = "P108", # property for employer
                                                     only_first = FALSE)) %>% # not only the first result
  unnest(worked_at_id) %>%
  filter(is.na(worked_at_id)==FALSE) %>% # remove those for which we have no employer
  mutate(worked_at_label = tw_get_label(worked_at_id)) %>% 
  # but keep in mind we are only interested in the employer if they are a university
  # so we ask what `instance of` the employer is. 
  mutate(employer_instance_of = tw_get_property_same_length(id = worked_at_id,
                                                            p = "P31",
                                                            only_first = FALSE)) %>%  
  unnest(employer_instance_of) %>% 
  mutate(employer_instance_of_label = tw_get_label(employer_instance_of)) %>% 
  # some institutions may be e.g. "instance of" -> "private university", not of "university"
  # so whe check what "subclass of" that id
  mutate(employer_instance_of2 = tw_get_property_same_length(id = worked_at_id,
                                                            p = "P31",
                                                            only_first = FALSE)) %>% 
  unnest(employer_instance_of2) %>% 
  mutate(employer_instance_of2_subclass_of = tw_get_property_same_length(id = employer_instance_of2,
                                                            p = "P279",
                                                            only_first = FALSE)) %>% 
  unnest(employer_instance_of2_subclass_of) %>% 
  # keep only if employer is a university (or something which is a subclass of university)
  filter(employer_instance_of == "Q3918" | employer_instance_of2_subclass_of == "Q3918") %>% 
  distinct(student_label, worked_at_id, worked_at_label) %>% 
  mutate(worked_at_coordinates = tw_get_property_same_length(worked_at_id,
                                                             p = "P625",
                                                             only_first = TRUE)) %>% 
  select(-worked_at_id) %>% 
  separate(worked_at_coordinates, into = c("lat", "lon"), sep = ",")
#> # A tibble: 19 × 4
#>    student_label                 worked_at_label            lat        lon      
#>    <chr>                         <chr>                      <chr>      <chr>    
#>  1 Ruth Benedict                 Columbia University        40.8075    -73.9619…
#>  2 Edward Sapir                  Yale University            41.311111… -72.9266…
#>  3 Edward Sapir                  University of Chicago      41.789722… -87.5997…
#>  4 Alexander Francis Chamberlain Clark University           42.250977  -71.8231…
#>  5 Alexander Goldenweiser        Columbia University        40.8075    -73.9619…
#>  6 Alexander Goldenweiser        University of Washington   47.654166… -122.308…
#>  7 Melville J. Herskovits        Northwestern University    42.054853  -87.6739…
#>  8 Melville J. Herskovits        Columbia University        40.8075    -73.9619…
#>  9 Melville J. Herskovits        Howard University          38.921666… -77.02   
#> 10 E. Adamson Hoebel             New York University        40.73      -73.995  
#> 11 Melville Jacobs               University of Washington   47.654166… -122.308…
#> 12 Alexander Lesser              Columbia University        40.8075    -73.9619…
#> 13 Alexander Lesser              Brandeis University        42.36566   -71.25974
#> 14 Alexander Lesser              Hofstra University         40.714605… -73.6004…
#> 15 Margaret Mead                 Columbia University        40.8075    -73.9619…
#> 16 Margaret Mead                 University of Rhode Island 41.4807    -71.5258 
#> 17 Paul Radin                    University of Chicago      41.789722… -87.5997…
#> 18 Paul Radin                    Fisk University            36.1688    -86.8047 
#> 19 Paul Radin                    Brandeis University        42.36566   -71.25974
```

Starting with version 0.5, to reduce typing,
`tw_get_property_same_length()` has now an alias, `tw_get_p()`, which
can be used in its stead.

## Qualifiers

In most cases, things are quite straightforward: each item has one or
more values for a given property.

However, some properties have additional qualifiers.

As an example, let’s look at someone whose life is seemingly less
adventurous than that of Margaret Mead, but whose Wikidata page has
properties with a more interesting combination of qualifiers: the
current president of the European Parliament David Sassoli
([Q2391857](https://www.wikidata.org/wiki/Q2391857)).

If we look at his “positions held”
([P39](https://www.wikidata.org/wiki/Property:P39)), we find the
following:

``` r
purrr::map_chr(
  .x = tw_get_property(id = "Q2391857", p = "P39") %>% dplyr::pull(value),
  .f = tw_get_label
)
#> [1] "member of the European Parliament"   
#> [2] "President of the European Parliament"
#> [3] "member of the European Parliament"   
#> [4] "member of the European Parliament"
```

He has been more than once “member of the European Parliament”, and once
“President of the European Parliament”. But this is not all that
Wikidata knows about it: each of these properties comes with qualifiers.

``` r
qualifiers_df <- tw_get_qualifiers(id = "Q2391857", p = "P39")
qualifiers_df
#> # A tibble: 21 × 8
#>    id    property qualifier_id qualifier_prope… qualifier_value qualifier_value…
#>    <chr> <chr>    <chr>        <chr>            <chr>           <chr>           
#>  1 Q239… P39      Q27169       P2937            Q17315694       wikibase-entity…
#>  2 Q239… P39      Q27169       P580             +2014-07-01T00… time            
#>  3 Q239… P39      Q27169       P4100            Q507343         wikibase-entity…
#>  4 Q239… P39      Q27169       P768             Q3677909        wikibase-entity…
#>  5 Q239… P39      Q27169       P1268            Q47729          wikibase-entity…
#>  6 Q239… P39      Q27169       P2715            Q1376095        wikibase-entity…
#>  7 Q239… P39      Q740126      P580             +2019-07-03T00… time            
#>  8 Q239… P39      Q740126      P1365            Q440710         wikibase-entity…
#>  9 Q239… P39      Q27169       P2937            Q4644021        wikibase-entity…
#> 10 Q239… P39      Q27169       P580             +2009-07-14T00… time            
#> # … with 11 more rows, and 2 more variables: rank <chr>, set <dbl>
```

As usual, Wikidata presents everything as combinations of properties and
values. Let’s translate each of these to their respective label, and
separate each set of information we have about the “positions held” by
Mr. Sassoli:

``` r
qualifiers_labelled_df <- qualifiers_df %>%
  dplyr::transmute(
    who = tw_get_label(id = id, language = "en"),
    did = tw_get_property_label(property = property, language = "en"),
    what = tw_get_label(id = qualifier_id, language = "en"),
    how = tw_get_property_label(property = qualifier_property, language = "en"),
    value = purrr::map_chr(
      .x = qualifier_value,
      .f = function(x) {
        if (stringr::str_starts(
          string = x,
          pattern = "Q"
        )) {
          tw_get_label(
            id = x,
            language = "en"
          )
        } else {
          stringr::str_extract(
            string = x,
            pattern = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"
          )
        }
      }
    ),
    set = set
  )

qualifiers_labelled_df %>%
  dplyr::group_by(set) %>%
  knitr::kable()
```

| who           | did           | what                                 | how                 | value                                            | set |
|:--------------|:--------------|:-------------------------------------|:--------------------|:-------------------------------------------------|----:|
| David Sassoli | position held | member of the European Parliament    | parliamentary term  | Eighth European Parliament                       |   1 |
| David Sassoli | position held | member of the European Parliament    | start time          | 2014-07-01                                       |   1 |
| David Sassoli | position held | member of the European Parliament    | parliamentary group | Progressive Alliance of Socialists and Democrats |   1 |
| David Sassoli | position held | member of the European Parliament    | electoral district  | Central Italy                                    |   1 |
| David Sassoli | position held | member of the European Parliament    | represents          | Democratic Party                                 |   1 |
| David Sassoli | position held | member of the European Parliament    | elected in          | 2014 European Parliament election                |   1 |
| David Sassoli | position held | President of the European Parliament | start time          | 2019-07-03                                       |   2 |
| David Sassoli | position held | President of the European Parliament | replaces            | Antonio Tajani                                   |   2 |
| David Sassoli | position held | member of the European Parliament    | parliamentary term  | Seventh European Parliament                      |   3 |
| David Sassoli | position held | member of the European Parliament    | start time          | 2009-07-14                                       |   3 |
| David Sassoli | position held | member of the European Parliament    | parliamentary group | Progressive Alliance of Socialists and Democrats |   3 |
| David Sassoli | position held | member of the European Parliament    | electoral district  | Central Italy                                    |   3 |
| David Sassoli | position held | member of the European Parliament    | represents          | Democratic Party                                 |   3 |
| David Sassoli | position held | member of the European Parliament    | elected in          | 2009 European Parliament election                |   3 |
| David Sassoli | position held | member of the European Parliament    | end time            | 2014-06-30                                       |   3 |
| David Sassoli | position held | member of the European Parliament    | parliamentary term  | Ninth European Parliament                        |   4 |
| David Sassoli | position held | member of the European Parliament    | start time          | 2019-07-02                                       |   4 |
| David Sassoli | position held | member of the European Parliament    | parliamentary group | Progressive Alliance of Socialists and Democrats |   4 |
| David Sassoli | position held | member of the European Parliament    | electoral district  | Italy                                            |   4 |
| David Sassoli | position held | member of the European Parliament    | represents          | Democratic Party                                 |   4 |
| David Sassoli | position held | member of the European Parliament    | elected in          | 2019 European Parliament election                |   4 |

That’s quite a lot of useful detail. The construction of the request can
be quite complicated, but keep in mind that if you do this
programmatically you will likely use this for filtering a specific piece
of information based on a combination of properties, and you will only
less frequently need to extract all available information.

Fundamentally, you won’t be touching anything that is not a vector or a
tidy data frame, which is ultimately a key goal of `tidywikidatar`: make
use of the wealth of information stored by Wikidata from R without
having to deal with either nested lists or SPARQL queries.

## Getting the right property when more than one is available

In Wikidata, the [order in which
statements](https://www.wikidata.org/wiki/Wikidata:Glossary#Order_of_statements)
for a property are shown depends on a number of factors. Consistent with
the API behaviour, `tidywikidatar` returns them in the same order as
they appear on the online on Wikidata dot org. Depending on the use case
and subsequent processing operations this may be either completely
irrelevant or very important, with a big impact even on the most basic
of queries.

For example, let’s compare results when we are trying to find out in
which country ([P17](https://www.wikidata.org/wiki/Property:P17)) London
([Q84](https://www.wikidata.org/wiki/Q84)) and Rome
([Q220](https://www.wikidata.org/wiki/Q220)) are located.

If we ask Wikidata in which country London is located, this is the
response we get:

``` r
tw_get_property(id = "Q84", p = "P17") %>%
  dplyr::mutate(value = tw_get_label(value))
#> # A tibble: 8 × 3
#>   id    property value                                      
#>   <chr> <chr>    <chr>                                      
#> 1 Q84   P17      Roman Empire                               
#> 2 Q84   P17      Kingdom of Essex                           
#> 3 Q84   P17      Kingdom of Mercia                          
#> 4 Q84   P17      Kingdom of Wessex                          
#> 5 Q84   P17      Kingdom of England                         
#> 6 Q84   P17      Great Britain                              
#> 7 Q84   P17      United Kingdom of Great Britain and Ireland
#> 8 Q84   P17      United Kingdom
```

These statements may all be fairly accurate at different points in time,
as we would see if we looked at the qualifiers of each of these
statements (see above) or check the respective [section on Wikidata’s
website](https://www.wikidata.org/wiki/Q84#P17). The order, however, is
determined by a number of factors and this may lead to inconsistent
results. If we are interested in having just one result, as is often the
case when processing large amounts of items, can we safely pick the
first (or last) and be sure it’s the more recent? As it emerges looking
at same for property for Rome, this is not the case.

``` r
tw_get_property(id = "Q220", p = "P17") %>%
  dplyr::mutate(value = tw_get_label(value))
#> # A tibble: 10 × 3
#>    id    property value                            
#>    <chr> <chr>    <chr>                            
#>  1 Q220  P17      Italy                            
#>  2 Q220  P17      Papal States                     
#>  3 Q220  P17      Kingdom of Italy                 
#>  4 Q220  P17      Ostrogothic Kingdom              
#>  5 Q220  P17      Byzantine Empire                 
#>  6 Q220  P17      Kingdom of Italy                 
#>  7 Q220  P17      Roman Kingdom                    
#>  8 Q220  P17      Roman Republic                   
#>  9 Q220  P17      Roman Empire                     
#> 10 Q220  P17      Western Roman Empire (395-476 AD)
```

So while we may be tempted to just keep the first statement returned by
Wikidata for the given property, this is probably not what we want.

``` r
tibble::tibble(city_qid = c("Q84", "Q220")) %>% 
  dplyr::mutate(city_label = tw_get_label(city_qid), 
                country_qid = tw_get_p(id = city_qid,
                                       p = "P17",
                                       only_first = TRUE)) %>% 
  dplyr::mutate(country_label = tw_get_label(country_qid))
#> # A tibble: 2 × 4
#>   city_qid city_label country_qid country_label
#>   <chr>    <chr>      <chr>       <chr>        
#> 1 Q84      London     Q2277       Roman Empire 
#> 2 Q220     Rome       Q38         Italy
```

Besides looking at the qualifiers, the standard way for Wikidata to
choose which is the “preferred” statement is the dedicated ranking
element (in the online interface, a small dot with arrows next to the
label), which can either be “preferred”, “normal”, or “deprecated”. In
piped operations, we get the “preferred” property by setting `preferred`
to `TRUE` in `tw_get_p()`.

``` r
tibble::tibble(city_qid = c("Q84", "Q220")) %>% 
  dplyr::mutate(city_label = tw_get_label(city_qid), 
                country_qid = tw_get_p(id = city_qid,
                                       p = "P17",
                                       preferred = TRUE,
                                       only_first = TRUE)) %>% 
  dplyr::mutate(country_label = tw_get_label(country_qid))
#> # A tibble: 2 × 4
#>   city_qid city_label country_qid country_label 
#>   <chr>    <chr>      <chr>       <chr>         
#> 1 Q84      London     Q145        United Kingdom
#> 2 Q220     Rome       Q38         Italy
```

Keep in mind that there may be more than one “preferred” statement, so
setting `preferred` to TRUE is no guarantee of having a single result:
for example, London is both “[capital
of](https://www.wikidata.org/wiki/Q84#P1376)”
([P1376](https://www.wikidata.org/wiki/Property:P1376)) the United
Kingdom and England, and both statements are “preferred”. Rome is
capital of Italy and Lazio (the region where it is located), and both
are “preferred”.

When the “preferred” option does not give the desired result or gives
more than one, in some cases it may be useful to use instead the
parameter `latest_start_time`, to pick the statement that has the most
recent “start time”
([P580](https://www.wikidata.org/wiki/Property:P580)) qualifier (this
can also be used in combination with `preferred`).

``` r
tibble::tibble(city_qid = c("Q84", "Q220")) %>% 
  dplyr::mutate(city_label = tw_get_label(city_qid), 
                country_qid = tw_get_p(id = city_qid,
                                       p = "P17",
                                       latest_start_time = TRUE, 
                                       only_first = TRUE)) %>% 
  dplyr::mutate(country_label = tw_get_label(country_qid))
#> # A tibble: 2 × 4
#>   city_qid city_label country_qid country_label 
#>   <chr>    <chr>      <chr>       <chr>         
#> 1 Q84      London     Q145        United Kingdom
#> 2 Q220     Rome       Q38         Italy
```

If none of the above works, then you may still be able to get consistent
results through customs solutions based on `tw_get_qualifiers()`, or by
checking the validity of alternative results based on their properties
(for example, many of the properties of “Roman empire”
([Q2277](https://www.wikidata.org/wiki/Q2277)) could be used to
determine that it is not, in fact, a contemporary country).

## Queries

All of the above works similarly to how we often use websites such as
Wikipedia, or search engines: we search for something specific to find
information about it. Wikidata, however, has powerful tools for complex
queries. Think something like “give me all of these fields for all items
that have this value for this property, but not that other value for
that other property”.

To achieve this, you can run queries, following [instructions on
Wikidata.org](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/queries/examples).
From R, you would run those using
`WikidataQueryServiceR::query_wikidata()`. This is powerful, but perhaps
somewhat intimidating for those who are less familiar with database
queries, SPARQL, and the likes.

`tidiwikidatar` does not currently plan to deal with complex queries.
However, at this stage it has a basic function, `tw_query`, which should
instantly make sense for R users.

Say, for example, you are interested in all women (P21 == Q6581072) who
are resistance fighters (P106 == Q6581072).

You can then make a data frame with two columns (p and q), and some
requirements, like this:

``` r
query_df <- tibble::tribble(
  ~p, ~q,
  "P106", "Q1397808",
  "P21", "Q6581072"
)

# if you prefer, you can input the same as a list, like this:
# query_l <- list(c(p = "P106", q = "Q1397808"),
#                c(p = "P21", q = "Q6581072"))

query_df
#> # A tibble: 2 × 2
#>   p     q       
#>   <chr> <chr>   
#> 1 P106  Q1397808
#> 2 P21   Q6581072
```

You can then pass it to `tw_query()`, and get a nicely formatted
dataframe with all women who are resistance fighters on Wikidata.

``` r
tw_query(query = query_df)
#> Rows: 759 Columns: 3
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (3): item, itemLabel, itemDescription
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 759 × 3
#>    id      label                  description                                   
#>    <chr>   <chr>                  <chr>                                         
#>  1 Q274041 Nanny of the Maroons   leader of Windward Maroons in Jamaica         
#>  2 Q276410 Marga Klompé           Dutch politician (1912-1986)                  
#>  3 Q283654 Maria Skobtsova        Russian saint                                 
#>  4 Q285995 Maria Restituta Kafka  Franciscan nun and nurse; Nazi critic; victim…
#>  5 Q304262 Hannie van Leeuwen     Dutch politician (1926-2018)                  
#>  6 Q324718 Martha Dodd            American spy for the Soviet Union             
#>  7 Q354512 Adele Stürzl           Austrian politician, member of the Austrian r…
#>  8 Q394661 Agnes Wendland         <NA>                                          
#>  9 Q441439 Henriette Roland Holst Dutch politician, editor (1869-1952)          
#> 10 Q443262 Lozen                  Apache prophetess and warrior                 
#> # … with 749 more rows
```

Or perhaps, you are interested only in women who are resistance fighters
who have “France” ([Q142](https://www.wikidata.org/wiki/Q142)) as
“country of citizenship”
([P27](https://www.wikidata.org/wiki/Property:P27))? And perhaps you
want the description in Italian, and if not available in French, and
only then look for other fallback options?

``` r
tibble::tribble(
  ~p, ~q,
  "P106", "Q1397808", # Occupation: resistance fighter
  "P21", "Q6581072", # Sex or gender: female
  "P27", "Q142"
) %>% # Country of citizenship: France
  tw_query(language = c("it", "fr"))
#> Rows: 125 Columns: 3
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (3): item, itemLabel, itemDescription
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 125 × 3
#>    id        label                           description                        
#>    <chr>     <chr>                           <chr>                              
#>  1 Q270319   Christiane Desroches Noblecourt egittologa e archeologa francese   
#>  2 Q18121470 Antoinette d'Harcourt           poétesse et résistante française   
#>  3 Q19300907 Lucette Pla-Justafré            enseignante et personnalité politi…
#>  4 Q19606396 Anise Postel-Vinay              résistante française               
#>  5 Q19631204 Cécile Rol-Tanguy               résistante française               
#>  6 Q20895003 Hélène Jakubowicz               résistante française               
#>  7 Q21009704 Madeleine Passot                résistante communiste française    
#>  8 Q21069334 Mireille Albrecht               fille de la résistante Berty Albre…
#>  9 Q5257705  Denise Laroque                  <NA>                               
#> 10 Q6837011  Michelle Dubois                 <NA>                               
#> # … with 115 more rows
```

You can also ask other fields, beyond label and description, using the
`field` parameter of `tw_query()`. But for this readme, I’ll keep things
simple. Do you want more information about these results without
learning yet another set of Wikidata terminology? You can still use the
same commands described above, e.g.

``` r
tibble::tribble(
  ~p, ~q,
  "P106", "Q1397808",
  "P21", "Q6581072",
  "P27", "Q142"
) %>%
  tw_query() %>%
  dplyr::slice(1) %>%
  get_bio()
#> Rows: 125 Columns: 3
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (3): item, itemLabel, itemDescription
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 1 × 4
#>   label                           description        year_of_birth year_of_death
#>   <chr>                           <chr>                      <dbl>         <dbl>
#> 1 Christiane Desroches Noblecourt French egyptologi…          1913          2011
```

Keep in mind that Wikidata queries are not cached locally.

## Getting Wikidata identifiers from a Wikipedia page

Besides querying Wikidata and using the basic `tw_search()` function
described above, `tidywikidatar` includes function that facilitate
retrieving Wikidata identifiers based on Wikipedia pages, as well as the
Wikidata identifiers corresponding to all the Wikipedia pages included
in a given Wikipedia page. This may be useful in particular on Wikipedia
pages that are lists of other pages, or as an alternative approach for
finding relations between various Wikidata items.

In this case, the starting point is usually the full URL or the title of
a Wikipedia page, which give the same result (the user, however, should
be mindful of redirection if using the title).

``` r
tw_get_qid_of_wikipedia_page(title = "Margaret Mead")
#> # A tibble: 1 × 7
#>   title  wikipedia_title wikipedia_id qid   description  disambiguation language
#>   <chr>  <chr>                  <int> <chr> <chr>        <lgl>          <chr>   
#> 1 Marga… Margaret Mead          19617 Q180… American cu… FALSE          en
```

``` r
tw_get_qid_of_wikipedia_page(url = "https://en.wikipedia.org/wiki/Margaret_Mead")
#> # A tibble: 1 × 7
#>   title  wikipedia_title wikipedia_id qid   description  disambiguation language
#>   <chr>  <chr>                  <int> <chr> <chr>        <lgl>          <chr>   
#> 1 Marga… Margaret Mead          19617 Q180… American cu… FALSE          en
```

Depending on the workflow, it is also possible to get the full link to
the Wikipedia page starting from a given Wikidata identifier.

``` r
tw_get_wikipedia(id = "Q180099")
#> [1] "https://en.wikipedia.org/wiki/Margaret Mead"
```

Who and what is mentioned in Margaret Mead’s Wikipedia page? As it turns
out, hundreds of pages, including a variety of people, places, concepts,
etc.

``` r
wikipedia_df <- tw_get_wikipedia(id = "Q180099") %>% 
  tw_get_links_from_wikipedia_page()

wikipedia_df
#> # A tibble: 891 × 5
#>    wikipedia_title      wikipedia_id wikidata_id wikidata_description   language
#>    <chr>                       <int> <chr>       <chr>                  <chr>   
#>  1 Alex Barker                    NA <NA>        <NA>                   en      
#>  2 Alfred S. Hayes                NA <NA>        <NA>                   en      
#>  3 Blackberry Winter: …           NA <NA>        <NA>                   en      
#>  4 Continuities in Cul…           NA <NA>        <NA>                   en      
#>  5 Culture and Commitm…           NA <NA>        <NA>                   en      
#>  6 John P. Gillin                 NA <NA>        <NA>                   en      
#>  7 A Darwinian Left          3890352 Q1762274    1999 book by Peter Si… en      
#>  8 A Rap on Race            14527943 Q4659145    Book by Margaret Mead… en      
#>  9 Abby Kelley               4056835 Q2820848    <NA>                   en      
#> 10 Abigail Adams              102745 Q206191     2nd First Lady of the… en      
#> # … with 881 more rows
```

What if we are potentially interested only in the people mentioned in
this page? We proceed as usual, checking which of these are “instance
of” (“P19”) “human” (“Q5”), and take it from there.

``` r
wikipedia_df %>% 
  dplyr::pull(wikidata_id) %>% 
  tw_get_property(p = "P31") %>% 
  dplyr::filter(value == "Q5")
```

All functions that interact with Wikipedia and the related MediaWiki API
are not cached locally at this stage.

## How caching works

`tidywikidatar` tries to reduce load on Wikidata’s server and speeding
up re-processing of scripts by caching data locally in sqlite databases.
They are stored locally in the folder defined by `tw_set_cache_folder()`
- by default, in the current working directory - when cache is enabled
(typically, with `tw_enable_cache()` at the beginning of a session).

To reduce the size of local files, if data are requested in a specific
language, then only data in that language are stored locally.

The easiest way to reset the cache is simply to delete the cache folder.

Results are stored in different databases by language, and function
used; `tw_search()`, `tw_get()`, and `tw_get_qualifiers()`, for example,
store data in different files.

`tw_query()` is never cached.

See the the dedicated vignette for more details on caching:
`vignette("caching")`.

## Requirements and installation issues

Fedora users may need to install the package `libjpeg-turbo-devel`,
which is required by one of the packages that `tidywikidatar` relies on.

## Copyright and credits

This package has been created by [Giorgio
Comai](https://giorgiocomai.eu), data analyst and researcher at
[OBCT/CCI](https://balcanicaucaso.org/), within the scope of
[EDJNet](https://europeandatajournalism.eu/), the European Data
Journalism Network.

It is distributed under the MIT license.
