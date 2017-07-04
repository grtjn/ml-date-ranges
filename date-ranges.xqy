xquery version "1.0-ml";

(:~ 
: This module provides functions that help generate value ranges for all date/time related data types.
: 
: Note:
: Although it also supports generating ranges for gMonthDay, MarkLogic currently does not allow
: range indexes on them yet.
:
: @author Geert Josten
: 
: @since Since:  June 30, 2017
: @version 1.0.0
:)
module namespace dr = "http://marklogic.com/date-ranges";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions"; (::)

declare option xdmp:mapping "false";

(:~ 
: Function for generating value ranges.
:
: Example:
: <pre> xquery version "1.0-ml";
:
: import module dr = "http://marklogic.com/date-ranges" at "/ext/mlpm_modules/ml-date-ranges/date-ranges.xqy";
:
: dr:ranges(
:   (xs:date("1996-10-25"), xs:date("2000-02-05")),
:   "year",
:   "interval=1"
: )</pre>
:
: Result:
: <pre> &gt;range start="1996-01-01" end="1997-01-01" label="1996 - 1997"/>
: &gt;range start="1997-01-01" end="1998-01-01" label="1997 - 1998"/>
: &gt;range start="1998-01-01" end="1999-01-01" label="1998 - 1999"/>
: &gt;range start="1999-01-01" end="2000-01-01" label="1999 - 2000"/>
: &gt;range start="2000-01-01" end="2001-01-01" label="2000 - 2001"/></pre>
:
: @param $minmax List of values from which min and max should be derived, should have uniform type.
: @param $level Level to which value ranges should be rounded, one of $dr:valid-levels.
: @param $options List of options, supported:
: <ul>
: <li>interval=n Multiplication factor for interval, n must be positive, default 1</li>
: </ul>
:
: @return Value ranges, expressed as start and end in datatype of $minmax, and label matching $level.
:
: @error
: <ul>
: <li>dr:INVALID-LEVEL Invalid level 'xxx', allowed are: yyy, zzz</li>
: <li>dr:INVALID-MINMAX Min/max must have one uniform type: xxx, yyy, zzz</li>
: <li>dr:INVALID-TYPE Invalid min/max type 'xxx', allowed are: yyy, zzz</li>
: <li>dr:INVALID-OPTION Interval must be positive integer: nnn</li>
: </ul>
:)
declare function dr:ranges(
  $minmax as xs:anyAtomicType+,
  $level as xs:string,
  $options as xs:string*
)
  as element(range)*
{
  if ($level = $dr:valid-levels) then

    let $type := dr:type($minmax)
    return

    if ($type = map:get($valid-level-types, $level)) then
      let $min := dr:min($minmax, $type)
      let $max := dr:max($minmax, $type)

      let $rounded-min := dr:round-to($min, $level)
      let $rounded-max := dr:round-to($max, $level)

      let $interval-option := dr:get-option($options, "interval", "1")
      let $interval-option := try {
        xs:positiveInteger($interval-option)
      } catch ($ignore) {
        error(xs:QName("dr:INVALID-OPTION"), "Interval must be positive integer: " || $interval-option)
      }

      let $interval :=
        if ($level eq "year") then
          xs:yearMonthDuration("P" || $interval-option || "Y")
        else if ($level eq "month") then
          xs:yearMonthDuration("P" || $interval-option || "M")
        else if ($level eq "day") then
          xs:dayTimeDuration("P" || $interval-option || "D")

        else if ($level eq "hour") then
          xs:dayTimeDuration("PT" || $interval-option || "H")
        else if ($level eq "minute") then
          xs:dayTimeDuration("PT" || $interval-option || "M")
        else if ($level eq "second") then
          xs:dayTimeDuration("PT" || $interval-option || "S")
        else
          error(xs:QName("dr:TODO-INTERVAL"), "Not implemented yet")

      let $diff := dr:diff($rounded-max, $rounded-min, $level)

      (: Note: using floor to determine nr-ranges, because we do 1 extra anyhow to ensure max boundary is included :)
      let $nr-ranges := floor($diff div $interval)

      for $i in (0 to $nr-ranges)
      let $start := $rounded-min + ($i * $interval)
      let $end := $start + $interval

      let $typed-start := dr:cast-to($start, $type)
      let $typed-end := dr:cast-to($end, $type)

      let $label-start := dr:label-for($start, $level, $type)
      let $label-end := dr:label-for($end, $level, $type)

      return
        <range start="{$typed-start}">{
          if (dr:gt($typed-end, $typed-start)) then
            attribute end { $typed-end }
          else (),
          if (dr:gt($typed-end, $typed-start)) then
            attribute label { $label-start || " - " || $label-end }
          else
            attribute label { $label-start || " - " }
        }</range>

    else
      error(xs:QName("dr:INVALID-TYPE"), "Invalid min/max type '" || $type || "' for level '" || $level || "', allowed are: " || string-join(map:get($valid-level-types, $level), ", "))

  else
    error(xs:QName("dr:INVALID-LEVEL"), "Invalid level '" || $level || "', allowed are: " || string-join($dr:valid-levels, ", "))
};

(:~ 
: Function for detecting most appropriate ranges level.
:
: @param  $minmax List of values from which min and max should be derived, should have uniform type.
:
: @return Appropriate level, or empty-sequence if none found.
:
: @error
: <ul>
: <li>dr:INVALID-MINMAX Min/max must have one uniform type: xxx, yyy, zzz</li>
: <li>dr:INVALID-TYPE Invalid min/max type 'xxx', allowed are: yyy, zzz</li>
: </ul>
:
:&lt;!-- START IGNORE -->
:)
declare function dr:detect-level(
  $minmax as xs:anyAtomicType+
)
  as xs:string?
{
  let $type := dr:type($minmax)
  return

  if ($type = $dr:valid-types) then
    let $min := dr:min($minmax, $type)
    let $max := dr:max($minmax, $type)
    let $rounded-min := dr:round-to($min, "second")
    let $rounded-max := dr:round-to($max, "second")
    return
      if (year-from-dateTime($rounded-min) ne year-from-dateTime($rounded-max)) then
        "year"
      else if (month-from-dateTime($rounded-min) ne month-from-dateTime($rounded-max)) then
        "month"
      else if (day-from-dateTime($rounded-min) ne day-from-dateTime($rounded-max)) then
        "day"
      else if (hours-from-dateTime($rounded-min) ne hours-from-dateTime($rounded-max)) then
        "hour"
      else if (minutes-from-dateTime($rounded-min) ne minutes-from-dateTime($rounded-max)) then
        "minute"
      else if (seconds-from-dateTime($rounded-min) ne seconds-from-dateTime($rounded-max)) then
        "second"
      else
        () (: diff too small for ranges :)
  else
    error(xs:QName("dr:INVALID-TYPE"), "Invalid min/max type '" || $type || "', allowed are: " || string-join($dr:valid-types, ", "))
};

declare private function dr:type(
  $items as xs:anyAtomicType+
)
  as xs:string
{
  let $types := distinct-values(
    $items ! local-name-from-QName(xdmp:type(.))
  )
  return
    if (count($types) eq 1) then
      $types
    else
      error(xs:QName("dr:INVALID-MINMAX"), "Min/max must have one uniform type: " || string-join($types, ", "))
};

declare private function dr:min(
  $items as xs:anyAtomicType+,
  $type as xs:string
)
  as xs:anyAtomicType
{
  if ($type eq "gMonthDay") then
  (: Make sure to apply a leapyear to handle Feb 29 correctly :)
    xs:gMonthDay(min($items ! xs:date(replace(string(.), "^-", "2016"))))
  else
    min($items)
};

declare private function dr:max(
  $items as xs:anyAtomicType+,
  $type as xs:string
)
  as xs:anyAtomicType
{
  if ($type eq "gMonthDay") then
    (: Make sure to apply a leapyear to handle Feb 29 correctly :)
    xs:gMonthDay(max($items ! xs:date(replace(string(.), "^-", "2016"))))
  else
    max($items)
};

declare private function dr:get-option(
  $options as xs:string*,
  $name as xs:string
)
  as xs:string?
{
  dr:get-option($options, $name, ())
};

declare private function dr:get-option(
  $options as xs:string*,
  $name as xs:string,
  $default as xs:string?
)
  as xs:string?
{
  let $matches := $options[starts-with(., $name || "=")]
  return
    if (exists($matches)) then
      substring-after($matches[1], $name || "=")
    else
      $default
};

declare private function dr:round-to(
  $val as xs:anyAtomicType,
  $level as xs:string
)
  as xs:anyAtomicType
{
  let $val :=
    (: Make sure to use January for gDay to make it go till 31 :)
    if ($val instance of xs:gDay) then
      xs:date(replace(string($val), "^--", "2016-01"))
    (: Make sure to apply a leapyear to handle Feb 29 correctly :)
    else if ($val instance of xs:gMonthDay) then
      xs:date(replace(string($val), "^-", "2016"))
    else
      $val
  return
    (: MarkLogic can't to arithmatic on Gregorian types, so cast to date/dateTime whatever comes in :)
    if ($level eq "year") then
      xs:date(xs:gYear($val))
    else if ($level eq "month") then
      xs:date(xs:gYearMonth($val))
    else if ($level eq "day") then
      xs:date($val)

    else if ($level eq "hour") then
      xs:dateTime(replace(string(xs:dateTime($val)), "(T\d{2}):\d{2}:\d{2}(\.\d+)?", "$1:00:00"))
    else if ($level eq "minute") then
      xs:dateTime(replace(string(xs:dateTime($val)), "(T\d{2}:\d{2}):\d{2}(\.\d+)?", "$1:00"))
    else if ($level eq "second") then
      xs:dateTime(replace(string(xs:dateTime($val)), "(T\d{2}:\d{2}:\d{2})(\.\d+)?", "$1"))

    else
      error(xs:QName("dr:TODO-ROUND"), "Not implemented yet")
};

declare private function dr:diff(
  $max as xs:anyAtomicType,
  $min as xs:anyAtomicType,
  $level as xs:string
)
  as xs:duration
{
  if ($level = ("year", "month")) then
    let $max := xs:date($max)
    let $min := xs:date($min)
    let $year-diff := year-from-date($max) - year-from-date($min)
    let $month-diff := month-from-date($max) - month-from-date($min)
    return
      xs:yearMonthDuration("P" || (($year-diff * 12) + $month-diff) || "M")
  else
    $max - $min
};

declare private function dr:gt(
  $left as xs:anyAtomicType,
  $right as xs:anyAtomicType
)
  as xs:boolean
{
  if ($left instance of xs:gMonthDay) then
    (: Make sure to apply a leapyear to handle Feb 29 correctly :)
    let $left := xs:date(replace(string($left), "^-", "2016"))
    let $right := xs:date(replace(string($right), "^-", "2016"))
    return
      $left gt $right
  else
    $left gt $right
};

declare private function dr:label-for(
  $val as xs:anyAtomicType,
  $level as xs:string,
  $type as xs:string
)
  as xs:anyAtomicType
{
  if ($level eq "year") then
    xs:gYear($val)
  else if ($level eq "month") then
    if ($type = ("gMonth", "gMonthDay")) then
      xs:gMonth($val)
    else
      xs:gYearMonth($val)
  else if ($level eq "day") then
    if ($type eq "gDay") then
      xs:gDay($val)
    else if ($type eq "gMonthDay") then
      xs:gMonthDay($val)
    else
      xs:date($val)

  else if ($level eq "hour") then
    if ($type eq "time") then
      replace(string($val), "^([^T]+T)?(\d{2}).*$", "T$2")
    else
      replace(string($val), "(T\d{2}).*$", "$1")
  else if ($level eq "minute") then
    if ($type eq "time") then
      replace(string($val), "^([^T]+T)?(\d{2}:\d{2}).*$", "T$2")
    else
      replace(string($val), "(T\d{2}:\d{2}).*$", "$1")
  else if ($level eq "second") then
    if ($type eq "time") then
      replace(string($val), "^([^T]+T)?(\d{2}:\d{2}:\d{2}).*$", "T$2")
    else
      replace(string($val), "(T\d{2}:\d{2}:\d{2}).*$", "$1")
  else
    error(xs:QName("dr:TODO-LABEL"), "Not implemented yet")
};

declare private function dr:cast-to(
  $val as xs:anyAtomicType,
  $type as xs:string
)
  as xs:anyAtomicType
{
  if ($type eq "date") then
    xs:date($val)
  else if ($type eq "dateTime") then
    xs:dateTime($val)
  else if ($type eq "gDay") then
    xs:gDay($val)
  else if ($type eq "gMonth") then
    xs:gMonth($val)
  else if ($type eq "gMonthDay") then
    xs:gMonthDay($val)
  else if ($type eq "gYear") then
    xs:gYear($val)
  else if ($type eq "gYearMonth") then
    xs:gYearMonth($val)
  else if ($type eq "time") then
    xs:time($val)
  else
    error(xs:QName("dr:TODO-CAST"), "Not implemented yet")
};

(:~&lt;!-- END IGNORE -->:)
declare private function dr:end-ignore() { () };

(:~ List of valid levels. Do not change. Currently:<ul>
: <li>year</li>
: <li>month</li>
: <li>day</li>
: <li>hour</li>
: <li>minute</li>
: <li>second</li>
: </ul>
:)
declare variable $dr:valid-levels as xs:string+ :=
  for $k in map:keys($valid-level-types)
  order by $k
  return $k
;

(:~ List of valid types, aggregated over all levels. Do not change. Currently:<ul>
: <li>date</li>
: <li>dateTime</li>
: <li>gday</li>
: <li>gMonth</li>
: <li>gMonthDay</li>
: <li>gYear</li>
: <li>gYearMonth</li>
: <li>time</li>
: </ul>
:&lt;!-- START IGNORE -->
:)
declare variable $dr:valid-types as xs:string+ :=
  for $t in distinct-values($dr:valid-levels ! map:get($valid-level-types, .))
  order by $t
  return $t
;

(:~&lt;!-- END IGNORE -->:)
declare private variable $valid-level-types := map:new((
  map:entry("year", ("date", "dateTime", "gYear", "gYearMonth")),
  map:entry("month", ("date", "dateTime", "gMonth", "gMonthDay", "gYearMonth")),
  map:entry("day", ("date", "dateTime", "gDay", "gMonthDay")),

  map:entry("hour", ("dateTime", "time")),
  map:entry("minute", ("dateTime", "time")),
  map:entry("second", ("dateTime", "time"))
));
