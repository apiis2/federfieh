sub GetData {

  my $sql="Set datestyle to 'german'";
  my $sql_ref = $apiis->DataBase->sys_sql($sql);
  my @sql;

  my $sql="select 
              (select short_name from codes where db_code=x.db_event_type) as ext_event_type,
	      event_dt,
	      event_dtend,
	      (select ext_id from unit where db_unit=x.db_location) as ext_location,
	      (select ext_id from unit where db_unit=x.db_sampler) as ext_pruefer,
          add_info
    from event x 
    order by ext_event_type, event_dt::date ";
  my $sql_ref = $apiis->DataBase->sys_sql($sql);
  if ($sql_ref->status == 1) {
    $apiis->status(1);
    $apiis->errors($sql_ref->errors);
    return;
  }

  #-- Schleife über alle Daten, abspeichern im array
  my %daten;my $i=0;my @ar_daten=();
  while( my $q = $sql_ref->handle->fetch ) {
    push(@ar_daten,[@$q]);
  }

  return \@ar_daten, ['ext_event_type','event_dt','event_dtend','ext_location', 'ext_pruefer','add_info'];
}


sub pdf {
  my $self =shift;
  my $data = shift;
  my $structure = shift;

  #use Data::Dumper;
  #print "++++>".Dumper($data)."<++++\n";

  my $latex_header = '
\documentclass[12pt,a4paper,DIV14,pdftex]{scrartcl}
\usepackage{german}
\usepackage[utf8]{inputenc}
\usepackage{multicol}
\usepackage{xcolor,colortbl}
\usepackage{ltablex}
\usepackage[pdftex]{graphicx}
%\pagestyle{empty}
\usepackage{marvosym} % some symboles
\usepackage{colortbl}
\usepackage{ifthen}

\usepackage{fancyhdr}
\pagestyle{fancy}
\parindent0mm
\sloppy{}

\begin{document}

\definecolor{mg}{gray}{.60}
\definecolor{lgrey}{rgb}{0.9,0.9,0.9}
%%\fancyheadoffset[r]{2.5mm}

';

  $self->{'_longtablecontent'} .= $latex_header;


  my $oldunit = '99';
  my $count = 1;
  foreach my $adr ( @{$data} ) {
    my @line = @{$adr};

    map { $_ = Apiis::Misc::MaskForLatex( $_ ) } @line;

    if ( $oldunit ne $line[0] ) {
      $self->{'_longtablecontent'} .= "\\end{tabularx}\n" if ( $count > 1 );
      $self->{'_longtablecontent'} .= "\\clearpage\n\n " if ( $count > 1 );
      $self->{'_longtablecontent'} .= "\\rhead{\\large \\textbf{  $line[0] }}
           \\chead{\\textbf{ \\raisebox{1ex}{Veranstaltungen} }}
           \\lhead{\\today\\\\Seite: \\thepage}
           \\lfoot{\\tiny }
	   \\cfoot{}\n\n";

      $self->{'_longtablecontent'} .= "\\begin{tabularx}{\\textwidth}{lllXXX}\\hline\n\n";
      $self->{'_longtablecontent'} .= "{\\textbf{ Prüfart}}& {\\textbf{ Datum}} & {\\textbf{ Datum-Ende}} & {\\textbf{ Ort}} &{\\textbf {Prüfer}} & {\\textbf{ Zusatz}}  \\\\  ";
    $self->{'_longtablecontent'} .= " \\hline \\endhead\n";
    }
    $count++;
    $oldunit = $line[0];

#    shift @line;
    my $outline = join( ' & ', @line );
    $self->{'_longtablecontent'} .= "$outline \\\\ \n";

    $self->{'_longtablecontent'} .= "\n";
    $self->{'_longtablecontent'} .= "\n";
    $self->{'_longtablecontent'} .= "\n";
    $self->{'_longtablecontent'} .= "\n";
    $self->{'_longtablecontent'} .= "\n";



  }

  $self->{'_longtablecontent'} .= "\\end{tabularx}\n";

}

1;
