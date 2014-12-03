#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Sql;

###### IMPORTS ################################################################

use Essence::Strict;

use parent 'Essence::Logger::Mixin';

use DBI;
use Carp;

###### EXPORTS ################################################################

use Exporter qw( import );
our @EXPORT_OK = qw( $IS_NULL $IS_NOT_NULL );

###### VARS ###################################################################

# use in where
our $IS_NULL = undef;
our $IS_NOT_NULL = sub { return ["`$_[0]` IS NOT NULL"] };

# defaults for connect
our $Database;
our $Username;
our $Password;

# "Members" for Essence::Sql
our $DB;
our $DBH;
our $InTransaction;

# If set database errors will throw this exception
our $Exception;

our $Debug;

###### METHODS ################################################################

# All methods are all lowercase 'coz all of them can be called like
#   Essence::Sql->method(...)

# ==== Support ================================================================

sub database_error
{
  return $Exception // $_[0]->fmt_error_msg_nl("Database error.");
}

sub _debug
{
  my $self = shift;
  if ((ref($self) && exists($self->{'debug'})) ? $self->{'debug'} : $Debug)
  {
    # my $category = shift;
    $self->LogDebug(shift,
        map { ref($_) ? $_ : "    $_" }
            grep { defined($_) } @_);
  }
}

sub _db_op
{
  my ($self, $handle, $op) = (shift, shift, shift);
  return $handle->$op(@_);
}

# ==== Constructors ===========================================================

sub new
{
  my $class = shift;

  # Essence::Sql->new($dbh, $db);
  return bless({ 'dbh' => $_[0], 'db' => $_[1] }, $class)
    if ref($_[0]);

  # Essence::Sql->new($db, $user, $pwd, $opts);
  return bless({}, $class)->connect(@_);
}

# DO NOT CALL WITH UNTRUSTED DB NAME
sub connect
{
  my ($self, $db, $user, $pwd, $opts) = @_;
  my ($dbh) = $self->dbh();

  $db   //= $Database // $ENV{'DB_DATABASE'};
  $user //= $Username // $ENV{'DB_USERNAME'};
  $pwd  //= $Password // $ENV{'DB_PASSWORD'};
  $opts //= {};

  if ($dbh)
  {
    my $db_ = $self->db();
    if ($db_ ~~ $db)
    {
      undef($dbh) unless $self->_db_op($dbh, 'ping');
    }
    else
    {
      $self->_debug('connect', "Switching to DB '$db'");

      if (!$self->_db_op($dbh, 'do', "USE `$db`"))
      {
        $self->_db_op($dbh, 'disconnect');
        undef($dbh);
      }
      else
      {
        $self->db($db);
      }
    }
  }

  if (!$dbh)
  {
    $self->_debug('connect', "Connecting to DB '$db'");

    my $connect = ($db =~ /:/) ? $db : "dbi:mysql:database=$db";
    $opts->{'mysql_enable_utf8'} = 1
      if (ref($opts) && !exists($opts->{'mysql_enable_utf8'}) &&
          ($connect =~ /:mysql:/));

    $dbh = DBI->connect($connect, $user, $pwd, $opts) or
      die $self->database_error('connect');

    $self->dbh($dbh, $db);
  }

  return $self;
}

# ==== DBH ====================================================================

sub dbh
{
  my $self = shift;
  my $dbh;

  if (@_)
  {
    if (ref($self))
    {
      $self->{'dbh'} = $dbh = $_[0];
      $self->{'db'} = $_[1];
    }
    else
    {
      $DBH = $dbh = $_[0];
      $DB = $_[1];
    }
  }
  else
  {
    $dbh = ref($self) ? $self->{'dbh'} : $DBH;
    $self->Croak("No dbh")
      unless ($dbh || wantarray);
  }

  return $dbh;
}

sub db
{
  my $self = shift;
  (ref($self) ? $self->{'db'} : $DB) = $_[0] if @_;
  return ref($self) ? $self->{'db'} : $DB;
}

# ==== Table ==================================================================

sub _table_
{
  my ($self, $op, $db, $table, $alias) = @_;

  $self->Croak("$op: No table is table spec")
    unless (defined($table) && ($table ne ''));

  $db = defined($db) ? "`$db`." : '';
  $alias = defined($alias) ? " AS `$alias`" : '';

  return "$db`$table`$alias";
}

sub _table
{
  my ($self, $op, $tbl_spec) = @_;

  return $self->_table_($op, undef, $tbl_spec, undef)
    unless ref($tbl_spec);
  return $self->_table_($op,
      $tbl_spec->{'db'},
      $tbl_spec->{'table'},
      $tbl_spec->{'alias'})
    if (ref($tbl_spec) eq 'HASH');

  $self->Croak("$op: Bad table spec")
    unless ((ref($tbl_spec) eq 'ARRAY') &&
            ($#{$tbl_spec} > 0) &&
            ($#{$tbl_spec} <= 2));

  my ($db, $table, $alias) =
      $#{$tbl_spec} ?
          @{$tbl_spec} :
          (undef, $tbl_spec->[0], undef);
  return $self->_table_($op, $db, $table, $alias);
}

# ==== WHERE ==================================================================

sub _join_where
{
  my $self = shift;
  my $op = shift;
  my (@sql, @params);

  my ($sql_, @params_);
  foreach (@_)
  {
    ($sql_, @params_) = @{$_};
    push(@sql, $sql_) if defined($sql_);
    push(@params, @params_);
  }

  @sql = map { "($_)" } @sql
    if (scalar(@sql) > 1);

  return (join(" $op ", @sql), @params);
}

sub _where_spec
{
  my ($self, $where) = @_;
  my $spec = shift(@{$where});

  if (($spec eq ':or') || ($spec eq ':and'))
  {
    my @terms;
    my $terms = shift(@{$where});
    if (ref($terms) eq 'ARRAY')
    {
      @terms =
          map { [$self->_join_where('AND', $self->_where_($_))] }
              @{$terms};
    }
    elsif (ref($terms) eq 'HASH')
    {
      @terms = $self->_where_($terms);
    }
    else
    {
      @terms = ($terms);
    }

    return [$self->_join_where(
        ($spec eq ':and') ? 'AND' : 'OR',
        @terms)];
  }
  else
  {
    $self->Croak("where: Bad special operator '$spec'");
  }
}

sub _where_op
{
  my ($self, $attr, $op, $args) = @_;
  if (!ref($op))
  {
    return ["`$attr` $op ?", $args];
  }
  elsif (ref($args) eq 'CODE')
  {
    return $args->($attr, $op);
  }
  # elsif (ref($args) eq 'SCALAR')
  # {
  #   return ["`$attr` $op $$args"];
  # }
  else
  {
    my $ref = ref($args);
    $self->Croak("where: `$attr` => { '$op' => $ref }");
  }
}

sub _where_attr
{
  my ($self, $where) = @_;
  my ($sql, @params);

  my $attr = shift(@{$where});
  my $cond = shift(@{$where});

  if (!defined($cond))
  {
    $sql = "`$attr` IS NULL";
  }
  elsif (!ref($cond))
  {
    $sql = "`$attr` = ?";
    @params = ($cond);
  }
  elsif (ref($cond) eq 'ARRAY')
  {
    @params = @{$cond};
    $self->Croak("where: `$attr` => []")
      unless @params;
    $sql = "`$attr` IN (" . join(', ', ('?') x scalar(@params))  . ')';
  }
  elsif (ref($cond) eq 'HASH')
  {
    return [ $self->_join_where('AND',
        map { $self->_where_op($attr, $_, $cond->{$_}) } keys(%{$cond})) ];
  }
  elsif (ref($cond) eq 'CODE')
  {
    return $cond->($attr);
  }
  # elsif (ref($cond) eq 'SCALAR')
  # {
  #   $sql = "`$attr` $$cond";
  # }
  else
  {
    $self->Croak("where: `$attr` => " . ref($cond));
  }

  return [$sql, @params];
}

sub _where__
{
  return ($_[1]->[0] =~ /^:/) ?
      shift->_where_spec(@_) :
      shift->_where_attr(@_);
}

sub _where_
{
  my ($self, $where_in) = @_;
  my @where_out;

  my @where_in;
  if (ref($where_in) eq 'HASH')
  {
    @where_in = ( %{$where_in} );
  }
  elsif (ref($where_in) eq 'ARRAY')
  {
    @where_in = @{$where_in};
  }
  elsif (defined($where_in))
  {
    my $ref = ref($where_in) || 'scalar';
    $self->Croak("where: Can't handle $ref");
  }

  push(@where_out, $self->_where__(\@where_in))
    while @where_in;

  return @where_out;
}

sub _where
{
  my $self = shift;
  my @where = $self->_join_where(
      'AND', $self->_where_(@_));
  $where[0] = ' WHERE ' . $where[0]
    if (@where && defined($where[0]) && ($where[0] ne ''));
  return @where;
}

# ==== INSERT =================================================================

# TODO options
# TODO bulk insert
# TODO check names
# TODO check values (CODE, etc.)
sub insert
{
  # my ($self, $table, $data, $opts) = @_;
  my ($self, $table, $data) = @_;
  my (@names, @values);

  my $sql_table = $self->_table('insert', $table);

  if (ref($data) eq 'HASH')
  {
    @names = keys(%{$data});
    @values = values(%{$data});
  }
  elsif (ref($data) eq 'ARRAY')
  {
    for ( my $i = 0 ; $i <= $#{$data} ; $i += 2)
    {
      push(@names, $data->[$i]);
      push(@values, $data->[$i+1]);
    }
  }
  elsif (defined($data))
  {
    $self->Croak("insert: Bad data")
  }

  my $names = join(', ', map { "`$_`" } @names);
  my $qs = join(', ', ('?') x scalar(@values));
  return ("INSERT INTO $sql_table ($names) VALUES ($qs)", @values);
}

# ==== SELECT =================================================================

sub _sort
{
  my ($self, $spec) = @_;
  $spec = (($spec =~ s/^([+-])//) && ($1 eq '-')) ?
      "`$spec` DESC" :
      "`$spec`";
  return $spec;
}

# TODO join, table aliases
sub select
{
  my ($self, $table, $fields, $where, $opts) = @_;
  my ($sql, @params);

  # TODO joins?
  my $sql_table = $self->_table('select', $table);

  my $f_sql;
  if (ref($fields))
  {
    $f_sql = join(', ', map { "`$_`" } @{$fields});
  }
  elsif (defined($fields))
  {
    $f_sql = $fields;
  }
  else
  {
    $f_sql = '*';
  }

  my ($w_sql, @w_params) = $self->_where($where, $opts);
  push(@params, @w_params);

  my ($s_sql, $o_sql, @o_params) = ('', '');
  if ($opts)
  {
    my $tmp;

    if (defined($tmp = $opts->{':limit'}))
    {
      $tmp = join(', ', @{$tmp})
        if (ref($tmp) eq 'ARRAY');
      $o_sql .= " LIMIT $tmp";
    }

    if (defined($tmp = $opts->{':lock'}))
    {
      if ($tmp eq 'r')
      {
        $o_sql .= ' LOCK IN SHARE MODE';
      }
      elsif ($tmp eq 'w')
      {
        $o_sql .= ' FOR UPDATE';
      }
      else
      {
        $self->Croak("select: Unknown lock mode '$tmp'");
      }
    }

    if ($tmp = $opts->{':sort'})
    {
      if (!ref($tmp))
      {
        $s_sql = ' ORDER BY ' . $self->_sort($tmp);
      }
      elsif (ref($tmp) eq 'ARRAY')
      {
        $s_sql = ' ORDER BY ' .
            join(', ', map { $self->_sort($_) } @{$tmp})
          if @{$tmp};
      }
      else
      {
        $self->Croak("select: Bad :sort");
      }
    }
  }

  $sql = "SELECT $f_sql FROM $sql_table$w_sql$s_sql$o_sql";
  push(@params, @o_params);

  return ($sql, @params);
}

# ==== UPDATE =================================================================

# TODO options
# TODO check names
# TODO check values (CODE, etc.)
sub update
{
  # my ($self, $table, $data, $where, $opts) = @_;
  my ($self, $table, $data, $where) = @_;

  my $sql_table = $self->_table('update', $table);

  my (@names, @values);
  if (ref($data) eq 'HASH')
  {
    @names = keys(%{$data});
    @values = values(%{$data});
  }
  elsif (ref($data) eq 'ARRAY')
  {
    for ( my $i = 0 ; $i <= $#{$data} ; $i += 2)
    {
      push(@names, $data->[$i]);
      push(@values, $data->[$i+1]);
    }
  }
  elsif (defined($data))
  {
    $self->Croak("update: Bad data");
  }

  $self->Croak("update: No data")
    unless @names;

  my $d_sql = join(', ', map { "`$_` = ?" } @names);

  # my ($w_sql, @w_params) = $self->_where($where, $opts);
  my ($w_sql, @w_params) = $self->_where($where);

  return ("UPDATE $sql_table SET $d_sql$w_sql", @values, @w_params);
}

# ==== DELETE =================================================================

# TODO options
sub delete
{
  # my ($self, $table, $where, $opts) = @_;
  my ($self, $table, $where) = @_;

  my $sql_table = $self->_table('delete', $table);

  # my ($w_sql, @w_params) = $self->_where($where, $opts);
  my ($w_sql, @w_params) = $self->_where($where);

  return ("DELETE FROM $sql_table$w_sql", @w_params);
}

# ==== do =====================================================================

sub do
{
  my ($self, $sql) = (shift, shift);

  my $opts;
  if (@_)
  {
    # Passing a HASH in @params doesn't make much sense
    if (ref($_[0]) eq 'HASH')
    {
      $opts = shift;
    }
    elsif (ref($_[-1]) eq 'HASH')
    {
      $opts = pop;
    }
  }

  $self->_debug('query', $sql, \@_, $opts);
  my $ret = $self->_db_op($self->dbh(), 'do', $sql, $opts, @_) or
    die $self->database_error('do');
  $self->_debug('result', $ret);

  return $ret;
}

sub _do
{
  my ($self, $what) = (shift, shift);
  # my ($sql, @params) = $self->$what(@_);
  return $self->do($self->$what(@_));
}

sub do_insert { return shift->_do('insert', @_) }
sub do_update { return shift->_do('update', @_) }
sub do_delete { return shift->_do('delete', @_) }

# ---- SELECT -----------------------------------------------------------------

sub do_select_array
{
  my $self = shift;
  my $rows;

  my ($sql, @params) =
      (defined($_[0]) && ($_[0] =~ /^select /i)) ?
          @_ : $self->select(@_);

  my $opts;
  if (@_)
  {
    # Passing a HASH in @params doesn't make much sense
    if (ref($params[0]) eq 'HASH')
    {
      $opts = shift(@params);
    }
    elsif (ref($params[-1]) eq 'HASH')
    {
      $opts = pop(@params);
    }
  }

  $self->_debug('query', $sql, \@params);
  $rows = $self->_db_op(
      $self->dbh(), 'selectall_arrayref', $sql, $opts, @params) or
    die $self->database_error('selectall');
  $self->_debug('result_set', $rows);

  return @{$rows};
}

sub do_select_row
{
  my @rows = shift->do_select_array(@_);
  carp "Query produced no result" unless @rows;
  carp "Query produced more than one row" if (scalar(@rows) > 1);
  return @rows ? @{$rows[0]} : () if wantarray;
  return $rows[0];
}

sub do_select_row_opt
{
  my @rows = shift->do_select_array(@_);
  carp "Query produced more than one row" if (scalar(@rows) > 1);
  return @rows ? @{$rows[0]} : () if wantarray;
  return $rows[0];
}

sub do_select_col
{
  return map { $_->[0] } shift->do_select_array(@_);
}

sub do_select_hash
{
  my $self = shift;
  my @ret;

  my ($sql, @params) =
      (defined($_[0]) && ($_[0] =~ /^select /i)) ?
          @_ : $self->select(@_);

  my $opts;
  if (@_)
  {
    # Passing a HASH in @params doesn't make much sense
    if (ref($params[0]) eq 'HASH')
    {
      $opts = shift(@params);
    }
    elsif (ref($params[-1]) eq 'HASH')
    {
      $opts = pop(@params);
    }
  }

  $self->_debug('query', $sql, \@params);

  my $sth = $self->_db_op($self->dbh(), 'prepare', $sql, $opts) or
    die $self->database_error('prepare');
  $self->_db_op($sth, 'execute', @params) or
    die $self->database_error('execute');

  my $row;
  push(@ret, $row) while ($row = $self->_db_op($sth, 'fetchrow_hashref'));
  die $self->database_error('fetch')
    if $self->_db_op($sth, 'err');

  $self->_debug('result_set', \@ret);

  return @ret;
}

# ==== Transactions ===========================================================

sub in_transaction
{
  my $self = shift;
  (ref($self) ? $self->{'in_transaction'} : $InTransaction) = $_[0]
    if @_;
  return ref($self) ? $self->{'in_transaction'} : $InTransaction;
}

sub begin
{
  my $self = shift;
  if (!$self->in_transaction())
  {
    $self->_debug('transaction', 'BEGIN');
    $self->_db_op($self->dbh(), 'begin_work') or
      die $self->database_error('begin');
    $self->in_transaction(1);
  }
}

sub commit
{
  my $self = shift;
  if ($self->in_transaction())
  {
    $self->_debug('transaction', 'COMMIT');
    $self->in_transaction(0);
    $self->_db_op($self->dbh(), 'commit') or
      die $self->database_error('commit');
  }
}

sub rollback
{
  my $self = shift;
  if ($self->in_transaction())
  {
    $self->_debug('transaction','ROLLBACK');
    $self->in_transaction(0);
    $self->_db_op($self->dbh(), 'rollback') or
      die $self->database_error('rollback');
  }
}

sub wrap_in_transaction
{
  my $self = shift;
  my @ret;

  foreach (@_)
  {
    eval
    {
      $self->begin();
      push(@ret, $_->($self));
      $self->commit();
    };
    if ($@)
    {
      my $saved = $@;
      $self->rollback();
      die $saved;
    }
  }

  return @ret if wantarray;
  return $ret[-1];
}

sub wrap_in_transaction_nodie
{
  my $self = shift;
  my @ret;

  foreach (@_)
  {
    eval { push(@ret, $self->wrap_in_transaction($_)) };
    warn $@ if $@;
  }

  return @ret if wantarray;
  return $ret[-1];
}

# ==== Disconnect =============================================================

sub disconnect
{
  my $self = shift;

  $self->_debug('connect', "Disconnect.");
  my $ret = $self->_db_op($self->dbh(), 'disconnect') or
    die $self->database_error('disconnect');

  $self->dbh(undef, undef);

  return $ret;
}

###############################################################################

1
