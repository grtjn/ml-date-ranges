xquery version "1.0-ml";

module namespace dr = "http://marklogic.com/date-ranges";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions"; (::)

declare option xdmp:mapping "false";

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

declare private variable $valid-level-types := map:new((
  map:entry("year", ("date", "dateTime", "gYear", "gYearMonth")),
  map:entry("month", ("date", "dateTime", "gMonth", "gMonthDay", "gYearMonth")),
  map:entry("day", ("date", "dateTime", "gDay", "gMonthDay")),

  map:entry("hour", ("dateTime", "time")),
  map:entry("minute", ("dateTime", "time")),
  map:entry("second", ("dateTime", "time"))
));

declare variable $dr:valid-levels :=
  for $k in map:keys($valid-level-types)
  order by $k
  return $k
;
declare variable $dr:valid-types :=
  for $t in distinct-values($dr:valid-levels ! map:get($valid-level-types, .))
  order by $t
  return $t
;

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
