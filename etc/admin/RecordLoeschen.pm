sub GetData {
    my ( $self, $ext_unit,$ext_id,$ext_animal,$guid ) = @_;
    my $structure = ['field'];

    if (!$guid or ( $guid eq '' )) {
        push( @{$data}, ["Keine interne Datensatz-ID (guid) angegeben."] );
        return $data, $structure;
    }   

    if (!$ext_animal or ( $ext_animal eq '' )) {
        push( @{$data}, ["Keine externe Tiernummer angegeben."] );
        return $data, $structure;
    }   

    my $sql     = "Set datestyle to 'german'";
    my $sql_ref = $apiis->DataBase->sys_sql($sql);

    # Tiernummer suchen und mit db_animal vergleichen 
    # Wenn Tier nicht gefunden, dann nicht vorhanden in dieser Kombination extern-intern 
    $sql="select a.db_animal from transfer a inner join unit b on a.db_unit=b.db_unit 
          where b.ext_unit='$ext_unit' and b.ext_id='$ext_id' and a.ext_animal='$ext_animal' ";
    $sql_ref = $apiis->DataBase->sys_sql($sql);
    if ( $sql_ref->status == 1 ) {
        $apiis->status(1);
        $apiis->errors( $sql_ref->errors );
        return;
    }
    if ( ( !$sql_ref->status ) and ( $sql_ref->{_rows} eq '0E0' ) ) {
        push( @{$data}, ["Kein Tier gefunden: $ext_unit - $ext_id - $ext_animal
                ($db_animal)"] );
        return $data, $structure;
    }

    #-- db_animal speichern
    my $db_animal; 
    while ( my $q = $sql_ref->handle->fetch ) {
        $db_animal=$q->[0];
    }
    
    foreach my $table ( $apiis->Model->tables ) {

        my $ok;
        #--- next table, if no column db_animal in table
        map { $ok = 1 if ( ( $_ eq 'db_animal' ) ) } @{ $apiis->Model->table($table)->cols };
        next if ( !$ok );

        my $sql = "select x.db_animal from $table x where db_animal=$db_animal and guid=$guid";

        #print $sql;
        $sql_ref = $apiis->DataBase->sys_sql($sql);
        if ( $sql_ref->status == 1 ) {
            $apiis->status(1);
            $apiis->errors( $sql_ref->errors );
            return;
        }

        #-- Schleife über alle Daten, abspeichern im array
        if ( ( !$sql_ref->status ) and ( $sql_ref->{_rows} ne '0E0' ) ) {
        
            my $sql = "delete from $table x where db_animal=$db_animal and guid=$guid";

            #print $sql;
            $sql_ref = $apiis->DataBase->sys_sql($sql);
            if ( $sql_ref->status == 1 ) {
                $apiis->status(1);
                $apiis->errors( $sql_ref->errors );
                return;
            }
    
            push( @{$data}, ["Der Datensatz für das Tier $ext_unit - $ext_id - $ext_animal (db_animal: $db_animal, guid: $guid) wurde in der Tabelle $table  gelöscht"] );
        }
    }

    $apiis->DataBase->dbh->commit;

    if ( $#{$data} == -1 ) {
        push( @{$data}, 'Keine Daten' );
    }
    return $data, $structure;

}

1;

