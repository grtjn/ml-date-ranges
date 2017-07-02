xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "../xray/src/assertions.xqy";

import module namespace dr = "http://marklogic.com/date-ranges" at "../date-ranges.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions"; (::)

declare option xdmp:mapping "false";

declare private function test:assert-equal($minmax, $test) {
  let $ranges := try {
    dr:ranges($minmax, $test/@level, tokenize($test/@options, ","))
  } catch ($e) {
    $e/error:format-string/data()
  }
  return assert:equal(
    $ranges,
    if ($ranges[1] instance of element(range)) then
      $test/range
    else
      normalize-space($test),
    "ranges(" || $test/@min || ", " || $test/@max || ", " || $test/@level || ", (" || $test/@options || "))"
  )
};

declare private function test:run-equal-tests($tests as element(ranges)+) {
  for $test in $tests
  let $minmax := (
    xdmp:value($test/@type||"('"||$test/@min||"')"),
    xdmp:value($test/@type||"('"||$test/@max||"')")
  )
  return test:assert-equal($minmax, $test)
};

declare %test:case function test:exceptions()
{
  test:run-equal-tests((
    (: level assertions :)
    <ranges type="xs:date" min="1999-12-15" max="2000-01-05" level="xxx" options="">
      Invalid level 'xxx', allowed are: day, hour, minute, month, second, year (dr:INVALID-LEVEL):
    </ranges>,
    (: non-date type assertions :)
    <ranges type="xs:int" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'int' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:unsignedInt" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'unsignedInt' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:long" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'long' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:unsignedLong" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'unsignedLong' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:float" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'float' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:double" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'double' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:decimal" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'decimal' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:yearMonthDuration" min="P1M" max="P2M" level="day" options="">
      Invalid min/max type 'yearMonthDuration' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:dayTimeDuration" min="P1D" max="P2D" level="day" options="">
      Invalid min/max type 'dayTimeDuration' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:string" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'string' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:anyURI" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'anyURI' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    (: day type assertions :)
    <ranges type="xs:gMonth" min="--11" max="--12" level="day" options="">
      Invalid min/max type 'gMonth' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:gYear" min="1999" max="2000" level="day" options="">
      Invalid min/max type 'gYear' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:gYearMonth" min="1999-12" max="2000-01" level="day" options="">
      Invalid min/max type 'gYearMonth' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:time" min="19:00:00" max="20:00:00" level="day" options="">
      Invalid min/max type 'time' for level 'day', allowed are: date, dateTime, gDay, gMonthDay (dr:INVALID-TYPE):
    </ranges>,
    (: month type assertions :)
    <ranges type="xs:gDay" min="---20" max="---21" level="month" options="">
      Invalid min/max type 'gDay' for level 'month', allowed are: date, dateTime, gMonth, gMonthDay, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:gYear" min="1999" max="2000" level="month" options="">
      Invalid min/max type 'gYear' for level 'month', allowed are: date, dateTime, gMonth, gMonthDay, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:time" min="19:00:00" max="20:00:00" level="month" options="">
      Invalid min/max type 'time' for level 'month', allowed are: date, dateTime, gMonth, gMonthDay, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    (: year type assertions :)
    <ranges type="xs:gDay" min="---20" max="---21" level="year" options="">
      Invalid min/max type 'gDay' for level 'year', allowed are: date, dateTime, gYear, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:gMonth" min="--11" max="--12" level="year" options="">
      Invalid min/max type 'gMonth' for level 'year', allowed are: date, dateTime, gYear, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:gMonthDay" min="--11-20" max="--12-21" level="year" options="">
      Invalid min/max type 'gMonthDay' for level 'year', allowed are: date, dateTime, gYear, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    <ranges type="xs:time" min="19:00:00" max="20:00:00" level="year" options="">
      Invalid min/max type 'time' for level 'year', allowed are: date, dateTime, gYear, gYearMonth (dr:INVALID-TYPE):
    </ranges>,
    (: interval assertions :)
    <ranges type="xs:date" min="1999-12-15" max="2000-01-05" level="day" options="interval=0">
      Interval must be positive integer: 0 (dr:INVALID-OPTION):
    </ranges>
  )),
  test:assert-equal(
    (current-date(), current-dateTime()),
    (: uniform types:)
    <ranges level="day" options="">
      Min/max must have one uniform type: date, dateTime (dr:INVALID-MINMAX):
    </ranges>
  )
};

declare %test:case function test:day-ranges()
{
  test:run-equal-tests((
    (: xs:date, crossing year and month boundary :)
    <ranges type="xs:date" min="1999-12-25" max="2000-01-05" level="day" options="interval=1">
      <range start="1999-12-25" end="1999-12-26" label="1999-12-25 - 1999-12-26"/>
      <range start="1999-12-26" end="1999-12-27" label="1999-12-26 - 1999-12-27"/>
      <range start="1999-12-27" end="1999-12-28" label="1999-12-27 - 1999-12-28"/>
      <range start="1999-12-28" end="1999-12-29" label="1999-12-28 - 1999-12-29"/>
      <range start="1999-12-29" end="1999-12-30" label="1999-12-29 - 1999-12-30"/>
      <range start="1999-12-30" end="1999-12-31" label="1999-12-30 - 1999-12-31"/>
      <range start="1999-12-31" end="2000-01-01" label="1999-12-31 - 2000-01-01"/>
      <range start="2000-01-01" end="2000-01-02" label="2000-01-01 - 2000-01-02"/>
      <range start="2000-01-02" end="2000-01-03" label="2000-01-02 - 2000-01-03"/>
      <range start="2000-01-03" end="2000-01-04" label="2000-01-03 - 2000-01-04"/>
      <range start="2000-01-04" end="2000-01-05" label="2000-01-04 - 2000-01-05"/>
      <range start="2000-01-05" end="2000-01-06" label="2000-01-05 - 2000-01-06"/>
    </ranges>,
    (: interval=2 :)
    <ranges type="xs:date" min="1999-12-25" max="2000-01-05" level="day" options="interval=2">
      <range start="1999-12-25" end="1999-12-27" label="1999-12-25 - 1999-12-27"/>
      <range start="1999-12-27" end="1999-12-29" label="1999-12-27 - 1999-12-29"/>
      <range start="1999-12-29" end="1999-12-31" label="1999-12-29 - 1999-12-31"/>
      <range start="1999-12-31" end="2000-01-02" label="1999-12-31 - 2000-01-02"/>
      <range start="2000-01-02" end="2000-01-04" label="2000-01-02 - 2000-01-04"/>
      <range start="2000-01-04" end="2000-01-06" label="2000-01-04 - 2000-01-06"/>
    </ranges>,
    (: xs:dateTime, crossing year and month boundary :)
    <ranges type="xs:dateTime" min="1999-12-25T00:00:00" max="2000-01-05T12:00:00" level="day" options="interval=1">
      <range start="1999-12-25T00:00:00" end="1999-12-26T00:00:00" label="1999-12-25 - 1999-12-26"/>
      <range start="1999-12-26T00:00:00" end="1999-12-27T00:00:00" label="1999-12-26 - 1999-12-27"/>
      <range start="1999-12-27T00:00:00" end="1999-12-28T00:00:00" label="1999-12-27 - 1999-12-28"/>
      <range start="1999-12-28T00:00:00" end="1999-12-29T00:00:00" label="1999-12-28 - 1999-12-29"/>
      <range start="1999-12-29T00:00:00" end="1999-12-30T00:00:00" label="1999-12-29 - 1999-12-30"/>
      <range start="1999-12-30T00:00:00" end="1999-12-31T00:00:00" label="1999-12-30 - 1999-12-31"/>
      <range start="1999-12-31T00:00:00" end="2000-01-01T00:00:00" label="1999-12-31 - 2000-01-01"/>
      <range start="2000-01-01T00:00:00" end="2000-01-02T00:00:00" label="2000-01-01 - 2000-01-02"/>
      <range start="2000-01-02T00:00:00" end="2000-01-03T00:00:00" label="2000-01-02 - 2000-01-03"/>
      <range start="2000-01-03T00:00:00" end="2000-01-04T00:00:00" label="2000-01-03 - 2000-01-04"/>
      <range start="2000-01-04T00:00:00" end="2000-01-05T00:00:00" label="2000-01-04 - 2000-01-05"/>
      <range start="2000-01-05T00:00:00" end="2000-01-06T00:00:00" label="2000-01-05 - 2000-01-06"/>
    </ranges>,
    (: xs:gDay, simple :)
    <ranges type="xs:gDay" min="---05" max="---15" level="day" options="interval=1">
      <range start="---05" end="---06" label="---05 - ---06"/>
      <range start="---06" end="---07" label="---06 - ---07"/>
      <range start="---07" end="---08" label="---07 - ---08"/>
      <range start="---08" end="---09" label="---08 - ---09"/>
      <range start="---09" end="---10" label="---09 - ---10"/>
      <range start="---10" end="---11" label="---10 - ---11"/>
      <range start="---11" end="---12" label="---11 - ---12"/>
      <range start="---12" end="---13" label="---12 - ---13"/>
      <range start="---13" end="---14" label="---13 - ---14"/>
      <range start="---14" end="---15" label="---14 - ---15"/>
      <range start="---15" end="---16" label="---15 - ---16"/>
    </ranges>,
    (: xs:gDay, max day boundary :)
    <ranges type="xs:gDay" min="---30" max="---31" level="day" options="interval=1">
      <range start="---30" end="---31" label="---30 - ---31"/>
      <range start="---31" label="---31 - "/>
    </ranges>,
    (: xs:gMonthDay, simple :)
    <ranges type="xs:gMonthDay" min="--12-05" max="--12-15" level="day" options="interval=1">
      <range start="--12-05" end="--12-06" label="--12-05 - --12-06"/>
      <range start="--12-06" end="--12-07" label="--12-06 - --12-07"/>
      <range start="--12-07" end="--12-08" label="--12-07 - --12-08"/>
      <range start="--12-08" end="--12-09" label="--12-08 - --12-09"/>
      <range start="--12-09" end="--12-10" label="--12-09 - --12-10"/>
      <range start="--12-10" end="--12-11" label="--12-10 - --12-11"/>
      <range start="--12-11" end="--12-12" label="--12-11 - --12-12"/>
      <range start="--12-12" end="--12-13" label="--12-12 - --12-13"/>
      <range start="--12-13" end="--12-14" label="--12-13 - --12-14"/>
      <range start="--12-14" end="--12-15" label="--12-14 - --12-15"/>
      <range start="--12-15" end="--12-16" label="--12-15 - --12-16"/>
    </ranges>,
    (: xs:gMonthDay, max day boundary :)
    <ranges type="xs:gMonthDay" min="--12-30" max="--12-31" level="day" options="interval=1">
      <range start="--12-30" end="--12-31" label="--12-30 - --12-31"/>
      <range start="--12-31" label="--12-31 - "/>
    </ranges>,
    (: xs:gMonthDay, leap year :)
    <ranges type="xs:gMonthDay" min="--02-29" max="--03-01" level="day" options="interval=1">
      <range start="--02-29" end="--03-01" label="--02-29 - --03-01"/>
      <range start="--03-01" end="--03-02" label="--03-01 - --03-02"/>
    </ranges>
  ))
};

declare %test:case function test:month-ranges()
{
  test:run-equal-tests((
    (: xs:date, crossing year and month boundary :)
    <ranges type="xs:date" min="1999-10-25" max="2000-02-05" level="month" options="interval=1">
      <range start="1999-10-01" end="1999-11-01" label="1999-10 - 1999-11"/>
      <range start="1999-11-01" end="1999-12-01" label="1999-11 - 1999-12"/>
      <range start="1999-12-01" end="2000-01-01" label="1999-12 - 2000-01"/>
      <range start="2000-01-01" end="2000-02-01" label="2000-01 - 2000-02"/>
      <range start="2000-02-01" end="2000-03-01" label="2000-02 - 2000-03"/>
    </ranges>,
    (: interval=2 :)
    <ranges type="xs:date" min="1999-10-25" max="2000-02-05" level="month" options="interval=2">
      <range start="1999-10-01" end="1999-12-01" label="1999-10 - 1999-12"/>
      <range start="1999-12-01" end="2000-02-01" label="1999-12 - 2000-02"/>
      <range start="2000-02-01" end="2000-04-01" label="2000-02 - 2000-04"/>
    </ranges>,
    (: xs:dateTime, crossing year and month boundary :)
    <ranges type="xs:dateTime" min="1999-10-25T00:00:00" max="2000-02-05T12:00:00" level="month" options="interval=1">
      <range start="1999-10-01T00:00:00" end="1999-11-01T00:00:00" label="1999-10 - 1999-11"/>
      <range start="1999-11-01T00:00:00" end="1999-12-01T00:00:00" label="1999-11 - 1999-12"/>
      <range start="1999-12-01T00:00:00" end="2000-01-01T00:00:00" label="1999-12 - 2000-01"/>
      <range start="2000-01-01T00:00:00" end="2000-02-01T00:00:00" label="2000-01 - 2000-02"/>
      <range start="2000-02-01T00:00:00" end="2000-03-01T00:00:00" label="2000-02 - 2000-03"/>
    </ranges>,
    (: xs:gMonth, max month boundary :)
    <ranges type="xs:gMonth" min="--05" max="--12" level="month" options="interval=1">
      <range start="--05" end="--06" label="--05 - --06"/>
      <range start="--06" end="--07" label="--06 - --07"/>
      <range start="--07" end="--08" label="--07 - --08"/>
      <range start="--08" end="--09" label="--08 - --09"/>
      <range start="--09" end="--10" label="--09 - --10"/>
      <range start="--10" end="--11" label="--10 - --11"/>
      <range start="--11" end="--12" label="--11 - --12"/>
      <range start="--12" label="--12 - "/>
    </ranges>,
    (: xs:gMonthDay, max month boundary :)
    <ranges type="xs:gMonthDay" min="--05-05" max="--12-05" level="month" options="interval=1">
      <range start="--05-01" end="--06-01" label="--05 - --06"/>
      <range start="--06-01" end="--07-01" label="--06 - --07"/>
      <range start="--07-01" end="--08-01" label="--07 - --08"/>
      <range start="--08-01" end="--09-01" label="--08 - --09"/>
      <range start="--09-01" end="--10-01" label="--09 - --10"/>
      <range start="--10-01" end="--11-01" label="--10 - --11"/>
      <range start="--11-01" end="--12-01" label="--11 - --12"/>
      <range start="--12-01" label="--12 - "/>
    </ranges>,
    (: xs:gMonthDay, leap year :)
    <ranges type="xs:gMonthDay" min="--02-29" max="--03-01" level="month" options="interval=1">
      <range start="--02-01" end="--03-01" label="--02 - --03"/>
      <range start="--03-01" end="--04-01" label="--03 - --04"/>
    </ranges>
  ))
};

declare %test:case function test:year-ranges()
{
  test:run-equal-tests((
    (: xs:date, crossing year and month boundary :)
    <ranges type="xs:date" min="1996-10-25" max="2000-02-05" level="year" options="interval=1">
      <range start="1996-01-01" end="1997-01-01" label="1996 - 1997"/>
      <range start="1997-01-01" end="1998-01-01" label="1997 - 1998"/>
      <range start="1998-01-01" end="1999-01-01" label="1998 - 1999"/>
      <range start="1999-01-01" end="2000-01-01" label="1999 - 2000"/>
      <range start="2000-01-01" end="2001-01-01" label="2000 - 2001"/>
    </ranges>,
    (: interval=2 :)
    <ranges type="xs:date" min="1996-10-25" max="2000-02-05" level="year" options="interval=2">
      <range start="1996-01-01" end="1998-01-01" label="1996 - 1998"/>
      <range start="1998-01-01" end="2000-01-01" label="1998 - 2000"/>
      <range start="2000-01-01" end="2002-01-01" label="2000 - 2002"/>
    </ranges>,
    (: xs:dateTime, crossing year and month boundary :)
    <ranges type="xs:dateTime" min="1996-10-25T00:00:00" max="2000-02-05T12:00:00" level="year" options="interval=1">
      <range start="1996-01-01T00:00:00" end="1997-01-01T00:00:00" label="1996 - 1997"/>
      <range start="1997-01-01T00:00:00" end="1998-01-01T00:00:00" label="1997 - 1998"/>
      <range start="1998-01-01T00:00:00" end="1999-01-01T00:00:00" label="1998 - 1999"/>
      <range start="1999-01-01T00:00:00" end="2000-01-01T00:00:00" label="1999 - 2000"/>
      <range start="2000-01-01T00:00:00" end="2001-01-01T00:00:00" label="2000 - 2001"/>
    </ranges>,
    (: xs:gYear, simple :)
    <ranges type="xs:gYear" min="1996" max="2000" level="year" options="interval=1">
      <range start="1996" end="1997" label="1996 - 1997"/>
      <range start="1997" end="1998" label="1997 - 1998"/>
      <range start="1998" end="1999" label="1998 - 1999"/>
      <range start="1999" end="2000" label="1999 - 2000"/>
      <range start="2000" end="2001" label="2000 - 2001"/>
    </ranges>,
    (: xs:gYearMonth, year and month boundary :)
    <ranges type="xs:gYearMonth" min="1996-10" max="2000-02" level="year" options="interval=1">
      <range start="1996-01" end="1997-01" label="1996 - 1997"/>
      <range start="1997-01" end="1998-01" label="1997 - 1998"/>
      <range start="1998-01" end="1999-01" label="1998 - 1999"/>
      <range start="1999-01" end="2000-01" label="1999 - 2000"/>
      <range start="2000-01" end="2001-01" label="2000 - 2001"/>
    </ranges>
  ))
};

declare %test:case function test:hour-ranges()
{
  test:run-equal-tests((
    (: xs:dateTime, crossing year, month, and day boundary :)
    <ranges type="xs:dateTime" min="1999-12-31T20:10:05" max="2000-01-01T02:03:04" level="hour" options="interval=1">
      <range start="1999-12-31T20:00:00" end="1999-12-31T21:00:00" label="1999-12-31T20 - 1999-12-31T21"/>
      <range start="1999-12-31T21:00:00" end="1999-12-31T22:00:00" label="1999-12-31T21 - 1999-12-31T22"/>
      <range start="1999-12-31T22:00:00" end="1999-12-31T23:00:00" label="1999-12-31T22 - 1999-12-31T23"/>
      <range start="1999-12-31T23:00:00" end="2000-01-01T00:00:00" label="1999-12-31T23 - 2000-01-01T00"/>
      <range start="2000-01-01T00:00:00" end="2000-01-01T01:00:00" label="2000-01-01T00 - 2000-01-01T01"/>
      <range start="2000-01-01T01:00:00" end="2000-01-01T02:00:00" label="2000-01-01T01 - 2000-01-01T02"/>
      <range start="2000-01-01T02:00:00" end="2000-01-01T03:00:00" label="2000-01-01T02 - 2000-01-01T03"/>
    </ranges>,
    (: xs:time, max hour boundary :)
    <ranges type="xs:time" min="20:10:05" max="23:03:04" level="hour" options="interval=1">
      <range start="20:00:00" end="21:00:00" label="T20 - T21"/>
      <range start="21:00:00" end="22:00:00" label="T21 - T22"/>
      <range start="22:00:00" end="23:00:00" label="T22 - T23"/>
      <range start="23:00:00" label="T23 - "/>
    </ranges>
  ))
};

declare %test:case function test:minute-ranges()
{
  test:run-equal-tests((
    (: xs:dateTime, crossing year, month, day, and hour boundary :)
    <ranges type="xs:dateTime" min="1999-12-31T23:56:05" max="2000-01-01T00:02:04" level="minute" options="interval=1">
      <range start="1999-12-31T23:56:00" end="1999-12-31T23:57:00" label="1999-12-31T23:56 - 1999-12-31T23:57"/>
      <range start="1999-12-31T23:57:00" end="1999-12-31T23:58:00" label="1999-12-31T23:57 - 1999-12-31T23:58"/>
      <range start="1999-12-31T23:58:00" end="1999-12-31T23:59:00" label="1999-12-31T23:58 - 1999-12-31T23:59"/>
      <range start="1999-12-31T23:59:00" end="2000-01-01T00:00:00" label="1999-12-31T23:59 - 2000-01-01T00:00"/>
      <range start="2000-01-01T00:00:00" end="2000-01-01T00:01:00" label="2000-01-01T00:00 - 2000-01-01T00:01"/>
      <range start="2000-01-01T00:01:00" end="2000-01-01T00:02:00" label="2000-01-01T00:01 - 2000-01-01T00:02"/>
      <range start="2000-01-01T00:02:00" end="2000-01-01T00:03:00" label="2000-01-01T00:02 - 2000-01-01T00:03"/>
    </ranges>,
    (: xs:time, max hour, and minute boundary :)
    <ranges type="xs:time" min="23:56:05" max="23:59:04" level="minute" options="interval=1">
      <range start="23:56:00" end="23:57:00" label="T23:56 - T23:57"/>
      <range start="23:57:00" end="23:58:00" label="T23:57 - T23:58"/>
      <range start="23:58:00" end="23:59:00" label="T23:58 - T23:59"/>
      <range start="23:59:00" label="T23:59 - "/>
    </ranges>
  ))
};

declare %test:case function test:second-ranges()
{
  test:run-equal-tests((
    (: xs:dateTime, crossing year, month, day, and hour boundary :)
    <ranges type="xs:dateTime" min="1999-12-31T23:59:56" max="2000-01-01T00:00:02" level="second" options="interval=1">
      <range start="1999-12-31T23:59:56" end="1999-12-31T23:59:57" label="1999-12-31T23:59:56 - 1999-12-31T23:59:57"/>
      <range start="1999-12-31T23:59:57" end="1999-12-31T23:59:58" label="1999-12-31T23:59:57 - 1999-12-31T23:59:58"/>
      <range start="1999-12-31T23:59:58" end="1999-12-31T23:59:59" label="1999-12-31T23:59:58 - 1999-12-31T23:59:59"/>
      <range start="1999-12-31T23:59:59" end="2000-01-01T00:00:00" label="1999-12-31T23:59:59 - 2000-01-01T00:00:00"/>
      <range start="2000-01-01T00:00:00" end="2000-01-01T00:00:01" label="2000-01-01T00:00:00 - 2000-01-01T00:00:01"/>
      <range start="2000-01-01T00:00:01" end="2000-01-01T00:00:02" label="2000-01-01T00:00:01 - 2000-01-01T00:00:02"/>
      <range start="2000-01-01T00:00:02" end="2000-01-01T00:00:03" label="2000-01-01T00:00:02 - 2000-01-01T00:00:03"/>
    </ranges>,
    (: xs:time, max hour, and minute boundary :)
    <ranges type="xs:time" min="23:59:56" max="23:59:59" level="second" options="interval=1">
      <range start="23:59:56" end="23:59:57" label="T23:59:56 - T23:59:57"/>
      <range start="23:59:57" end="23:59:58" label="T23:59:57 - T23:59:58"/>
      <range start="23:59:58" end="23:59:59" label="T23:59:58 - T23:59:59"/>
      <range start="23:59:59" label="T23:59:59 - "/>
    </ranges>
  ))
};

declare %test:case function test:detect-level() {
  for $test in (
    (: exceptions :)
    <ranges type="xs:string" min="1996-10-25" max="2000-02-05">
      Invalid min/max type 'string', allowed are: date, dateTime, gDay, gMonth, gMonthDay, gYear, gYearMonth, time (dr:INVALID-TYPE):
    </ranges>,
    (: date :)
    <ranges type="xs:date" min="1996-10-25" max="2000-02-05">
      year
    </ranges>,
    <ranges type="xs:date" min="1996-10-25" max="1996-12-05">
      month
    </ranges>,
    <ranges type="xs:date" min="1996-10-25" max="1996-10-26">
      day
    </ranges>,
    <ranges type="xs:date" min="1996-10-25" max="1996-10-25">
    </ranges>,
    (: dateTime :)
    <ranges type="xs:dateTime" min="1999-12-31T00:00:02" max="2000-01-01T23:59:56">
      year
    </ranges>,
    <ranges type="xs:dateTime" min="1999-11-30T00:00:02" max="1999-12-31T23:59:56">
      month
    </ranges>,
    <ranges type="xs:dateTime" min="1999-12-30T00:00:02" max="1999-12-31T23:59:56">
      day
    </ranges>,
    <ranges type="xs:dateTime" min="1999-12-31T00:00:02" max="1999-12-31T23:59:56">
      hour
    </ranges>,
    <ranges type="xs:dateTime" min="1999-12-31T00:00:02" max="1999-12-31T00:59:56">
      minute
    </ranges>,
    <ranges type="xs:dateTime" min="1999-12-31T00:00:02" max="1999-12-31T00:00:56">
      second
    </ranges>,
    <ranges type="xs:dateTime" min="1999-12-31T00:00:02" max="1999-12-31T00:00:02">
    </ranges>,
    (: gDay :)
    <ranges type="xs:gDay" min="---30" max="---31">
      day
    </ranges>,
    (: gMonth :)
    <ranges type="xs:gMonth" min="--05" max="--12">
      month
    </ranges>,
    (: gMonthDay :)
    <ranges type="xs:gMonthDay" min="--12-05" max="--12-15">
      day
    </ranges>,
    (: xs:gYear :)
    <ranges type="xs:gYear" min="1996" max="2000">
      year
    </ranges>,
    (: xs:gYearMonth :)
    <ranges type="xs:gYearMonth" min="1996-10" max="2000-02">
      year
    </ranges>,
    (: time :)
    <ranges type="xs:time" min="23:59:56" max="23:59:59">
      second
    </ranges>
  )
  let $minmax := (
    xdmp:value($test/@type||"('"||$test/@min||"')"),
    xdmp:value($test/@type||"('"||$test/@max||"')")
  )
  let $level := try {
    dr:detect-level($minmax)
  } catch ($e) {
    $e/error:format-string/data()
  }
  return assert:equal(
    string($level),
    normalize-space($test),
    "detect-level(" || $test/@min || ", " || $test/@max || "))"
  )
};

(: test helper functions :)

declare private variable $root := resolve-uri("..", xdmp:modules-root() || xdmp:get-request-path());

declare private function test:eval($query, $vars) {
  xdmp:eval(
    $query,
    $vars,
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <root>{$root}</root>
      </options>
  )
};