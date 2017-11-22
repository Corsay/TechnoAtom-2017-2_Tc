use strict;
use warnings;
use 5.10.0;
use Getopt::Long;

my @key_v = (0, 0);
my $numeric_sort_v = 0;
my $reverse_v = 0;
my $unique_v = 0;
my $month_sort_v = 0;
my $ignore_leading_blanks_v = 0;
my $check_v = 0;
my $human_numeric_sort_v = 0;
my $file_take = 0;
my @sort_data;

my %month_h = (JAN => 1, FEB => 2, MAR => 3, APR => 4, 
               MAY => 5, JUN => 6, JUL => 7, AUG => 8, 
               SEP => 9, OCT => 10, NOV => 11, DEC => 12);


my %num_hum = (NS => 1, K => 2 ** 10, 
               M => 2 ** 20, G => 2 ** 30, 
               T => 2 ** 40, P => 2 ** 50);


GetOptions ("k|key=s"=> \&parse_key_v, "n|numeric_sort" => \$numeric_sort_v,
            "r|reverse" => \$reverse_v, "u|unique" => \$unique_v,
            "M|month_sort" => \$month_sort_v, 
            "b|ignore_leading_blanks" => \$ignore_leading_blanks_v,
            "c|check" => \$check_v, 
            "h|human_numeric_sort" => \$human_numeric_sort_v, 
            "<>" => \&take_data_from_files);


push @sort_data, <> if (!$file_take);

my $cmp_func;

if ($numeric_sort_v) {
    $cmp_func = \&numeric_str_cmp;
}
elsif ($month_sort_v) {
    $cmp_func = \&month_str_cmp;
}
elsif ($human_numeric_sort_v) {
    $cmp_func = \&hnumeric_str_cmp;
}
else {
    $cmp_func = \&str_cmp;
}


delete_leading_blanks(\@sort_data) if ($ignore_leading_blanks_v);

if ($check_v) {
    my ($err_line, $err_value, $code) = check_for_sort(\@sort_data, $cmp_func, $reverse_v, $key_v[0], $key_v[1]);

    exit 0 if (!$code);

    die "$0: line: $err_line incorrect order : $err_value";
}
else {
    unique_sort_array(\@sort_data, 0, 0) if ($unique_v);
    p_sort(\@sort_data, $cmp_func, $reverse_v, $key_v[0], $key_v[1]);
}

print @sort_data;

sub check_for_sort {
    my($arr, $sort_func, $rev, $b_col, $e_col) = @_;

    if (@{$arr} < 2) {
        return ("", "", 0);
    }


    my $err_cmp_res;

    if (!$rev) {
       $err_cmp_res = 1;
    }
    else {
       $err_cmp_res = -1;
    }

    for (my $it = 0; $it < @{$arr} - 1; ++$it) {
            if (($sort_func->(get_substr($arr->[$it], $b_col, $e_col), 
                             get_substr($arr->[$it + 1], $b_col, $e_col))) == $err_cmp_res) {
                return ($it."-".($it+1), $arr->[$it + 1], 1);
            }
    }
    
    return ("", "", 0);
}


sub delete_leading_blanks {
    my $str_arr = shift @_;

    for (my $it = 0; $it < @{$str_arr}; ++$it) {
        $str_arr->[$it] =~ s/\s+$//;
        $str_arr->[$it] .= "\n";
    }
}


sub p_sort {
    my($arr, $sort_func, $rev, $b_col, $e_col) = @_;
    
    if (!$rev) {
        @{$arr} = sort {$sort_func->(get_substr($a, $b_col, $e_col), 
                                      get_substr($b, $b_col, $e_col))} @{$arr};
    }
    else {
        @{$arr} = sort { $sort_func->(get_substr($b, $b_col, $e_col), 
                                      get_substr($a, $b_col, $e_col))} @{$arr};
    }
}

sub str_cmp {
    my ($str1, $str2) = @_;

    return $str1 cmp $str2;
}

sub numeric_str_cmp {
    my ($str1, $str2) = @_;

    $str1 =~ /^\s*(?<NUM1>[+-]?\d+(?:\.\d+)?)(?<TAIL1>.*)$/;

    my $num1 = $+{NUM1} // 0; 
    my $str_tail1 = $+{TAIL1} // "";

    $str2 =~ /^\s*(?<NUM2>[+-]?\d+(?:\.\d+)?)(?<TAIL2>.*)$/;

    my $num2 = $+{NUM2} // 0; 
    my $str_tail2 = $+{TAIL2} // "";
 
    return $num1 <=> $num2 || $str_tail1 cmp $str_tail2;
}


sub hnumeric_str_cmp {
    my ($str1, $str2) = @_;


    $str1 =~ /^\s*(?<NUM1>[+-]?\d+(?:\.\d+)?)(?<SUF1>[KMGTP])?(?<TAIL1>.*)$/; 

    my $num1 = $+{NUM1} // 0; 
    my $suf1 = $+{SUF1} // "NS";
    my $str_tail1 = $+{TAIL1} // "";

    $str2 =~ /^\s*(?<NUM2>[+-]?\d+(?:\.\d+)?)(?<SUF2>[KMGTP])?(?<TAIL2>.*)$/;

    my $num2 = $+{NUM2} // 0; 
    my $suf2 = $+{SUF2} // "NS";
    my $str_tail2 = $+{TAIL2} // "";

    $num1 *= $num_hum{$suf1};
    $num2 *= $num_hum{$suf2};

    return $num1 <=> $num2 || $str_tail1 cmp $str_tail2;
}

sub month_str_cmp {
    my ($str1, $str2) = @_;

    my $mk_rex =  join "|", keys %month_h; 

    $str1 =~ /^\s*(?<MONTH1>$mk_rex)(?<TAIL1>.*)$/i;

    my $cmp_v1 = 0;

    if (defined $+{MONTH1}) {
        $cmp_v1 = $month_h{uc $+{MONTH1}}
    }
 
    my $str_tail1 = $+{TAIL1} // "";

    $str2 =~ /^\s*(?<MONTH2>$mk_rex)(?<TAIL2>.*)$/i;

    my $cmp_v2 = 0;

    if (defined $+{MONTH2}) {
        $cmp_v2 = $month_h{uc $+{MONTH2}}
    }
 
    my $str_tail2 = $+{TAIL2} // "";



    return $cmp_v1 <=> $cmp_v2 || $str_tail1 cmp $str_tail2;
}


sub unique_sort_array {
    my ($arr, $b_col, $e_col) = @_;

    @{$arr} = keys %{{map { get_substr($_, $b_col, $e_col) => 1} @{$arr}}};
}

sub get_substr {
    my ($str, $begin, $end) = @_;

    if ($begin < 0 || $end < 0) {
        die "Incorrect arguments";
    }

    $begin -= 1 if ($begin > 0);

    if ($end != 0) {
        die "Incorrect arguments" if ($begin > $end);

        $end = $end - $begin + 1;
    }
    else {
        $end = length $str;
    }

    $str =~ m/^(?:\s*\S+\s+){$begin}(?<RES>(?:\s*\S+\s*){0,$end})(?:.*)$/;

    return $+{RES} // "";
}


sub parse_key_v {
    my $str_k = $_[1];

    die "option <key> is incorrect" if ($str_k !~ /^(?<BEGIN>[1-9]+)(?:,(?<END>[1-9]+))?$/);

    my $key_v1 = $+{BEGIN} // 0;
    my $key_v2 = $+{END} // 0;

    if ($key_v2 != 0 && $key_v1 >  $key_v2) {
         die "option <key> is incorrect";
    }

    $key_v[0] = $key_v1;
    $key_v[1] = $key_v2;
}

sub take_data_from_files {
    my ($file_path) = @_;
    $file_take = 1;

    open my $fd, "<", $file_path or die "Can't open file $file_path";

    push @sort_data, <$fd>;

    close $fd;
}


1;

