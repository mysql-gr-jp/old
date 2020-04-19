<?

$view_count = 5;

$max_page = mysql_query("select count(*) from tbl");

$max_page = (int)(($max_page + $view_count - 1) / $max_page);

if (!isset($current_page)) {
	$current_page = 1;
} else if ($current_page < 1) {
	$current_page = 1;
} else if ($current_page > $max_page) {
	$current_page = $max_page;
}

$view_current = $view_count * ($current_page - 1);

$result = mysql_query("select * from tbl limit $view_current,$view_count");

?>

<form name="foo" action="foo.php3" method=POST>
 <input type=hidden name="current_page" value="<? echo $current_page; ?>">

<input type=button value="