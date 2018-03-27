package Thruk::Views::ExcelRenderer;

=head1 NAME

Thruk::Views::ExcelRenderer - Render Excel files

=head1 DESCRIPTION

Excel file renderer

=cut

use strict;
use warnings;
use Carp qw/confess/;
use Time::HiRes qw/gettimeofday tv_interval/;

=head1 METHODS

=head2 register

    register this renderer

=cut
sub register {
    return;
}

=head2 render_excel

    $c->render_excel()

=cut
sub render_excel {
    my($c) = @_;
    my $t1 = [gettimeofday];
    my $template = $c->stash->{'template'};
    $c->stats->profile(begin => "render_excel: ".$template);
    my $output = render($c, $template);
    $c->{'rendered'} = 1;
    $c->res->content_type('application/x-msexcel');
    $c->res->body($output);
    $c->stats->profile(end => "render_excel: ".$template);
    my $elapsed = tv_interval($t1);
    $c->stash->{'total_render_waited'} += $elapsed;
    return($output);
}

=head2 render

    render template and return output

=cut
sub render {
    my($c, $template) = @_;
    my $t1 = [gettimeofday];
    $c->stats->profile(begin => "render: ".$template);
    my $worksheets;
    Thruk::Views::ToolkitRenderer::render($c, $template, undef, \$worksheets);
    require IO::String;
    require Excel::Template;
    my $fh = IO::String->new($worksheets);
    $fh->pos(0);

    my $excel_template = eval { Excel::Template->new(file => $fh) };
    if($@) {
        warn $worksheets;
        confess $@;
    }
    my $output = ''.$excel_template->output;
    $c->stats->profile(end => "render: ".$template);
    my $elapsed = tv_interval($t1);
    $c->stash->{'total_render_waited'} += $elapsed;
    return($output);
}

1;
__END__

=head1 SYNOPSIS

    $c->render_excel();

=head1 DESCRIPTION

This module renders L<use Excel::Template> data.

=head1 SEE ALSO

L<Excel::Template>.

=cut
