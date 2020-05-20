$pdf_mode = 1;
$postscript_mode = 0;
#dvi_mode = 0;
$pdflatex = "pdflatex --halt-on-error --shell-escape %O %S";
$max_repeat = 10;

$bibtex_use = 2;

$halt_on_error = 1;
$success_cmd = "echo 'WARNINGS' ; echo ; rubber-info --errors %R ; rubber-info --warnings %R; echo";
$failure_cmd = "echo 'ERRORS' ; echo ; rubber-info --errors %R; echo";
