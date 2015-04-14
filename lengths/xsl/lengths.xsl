<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr-hex-private="http://transpect.io/xslt-util/hex/private"
  xmlns:tr="http://transpect.io"
  version="2.0">

  <xsl:function name="tr:length-to-unitless-twip" as="xs:double?">
    <xsl:param name="in" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="matches($in, '^-?[\d.]+mm$')">
        <xsl:sequence select="number(replace($in, 'mm$', '')) * 56.6929"/>
      </xsl:when>
      <xsl:when test="matches($in, '^-?[\d.]+pt$')">
        <xsl:sequence select="number(replace($in, 'pt$', '')) * 20"/>
      </xsl:when>
      <xsl:when test="matches($in,  '^-?[\d.]+%$')">
        <!-- * 50 – why is that?? -->
        <xsl:sequence select="number(replace($in, '%$', '')) * 50"/>
      </xsl:when>
      <xsl:when test="$in eq 'auto'"/>
      <xsl:otherwise>
        <xsl:message>Value '<xsl:value-of select="$in"/>' is not supported in function
          tr:length-to-unitless-twip. Allowed values are mm, pt, % and auto.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- for OOXML’s w:sz which is 1/8 pt, see 17.3.4 Border Properties (CT_Border) in ISO/IEC 29500-1 -->
  <xsl:function name="tr:length-to-border-width-type" as="xs:double?">
    <xsl:param name="in" as="xs:string"/>
    <xsl:sequence select="round(tr:length-to-unitless-twip($in) idiv 5 * 2)"/>
  </xsl:function>

  <xsl:decimal-format name="tr:single-digit"/>

  <xsl:function name="tr:percent" as="xs:string?">
    <xsl:param name="val" as="xs:double"/>
    <xsl:param name="total" as="xs:double"/>
    <xsl:choose>
      <xsl:when test="$total = 0"/>
      <xsl:otherwise>
        <xsl:sequence
          select="concat(format-number(round(1000 * $val div $total) * 0.1, '#.0'), '%')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:ast" as="xs:string?">
    <xsl:param name="val" as="xs:double"/>
    <xsl:param name="total" as="xs:double"/>
    <xsl:choose>
      <xsl:when test="$total = 0"/>
      <xsl:otherwise>
        <xsl:sequence
          select="concat(format-number(round(1000 * $val div $total) * 0.001, '#.000'), '*')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:unitless-twip-to-pt" as="xs:string">
    <xsl:param name="twips" as="xs:double"/>
    <xsl:sequence select="concat($twips * 0.05, 'pt')"/>
  </xsl:function>

  <xsl:param name="tr:relative-table-widths" as="xs:string?">
    <!-- 'percent' or 'ast' (or nothing for no transformation)
    ast: '0.4*' corresponds to '40%'. 
    If you transform your document in multiple passes (where each pass corresponds to one XSLT mode),
    please make sure that you only set this parameter for one of the modes. Otherwise it will try
    to do this transformation over and over again, and it probably won’t work if the colwidth values 
    are already relative. -->
  </xsl:param>

  <xsl:function name="tr:index-of" as="xs:integer">
    <xsl:param name="nodes" as="node()+"/>
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="index-of(for $n in $nodes return generate-id($n), generate-id($node))"/>
  </xsl:function>

  <xsl:template match="*:tgroup[$tr:relative-table-widths]" mode="#all" priority="+1">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="colspec-colwidths-in-twips" as="xs:double*"
        select="for $cw in *:colspec/@colwidth return tr:length-to-unitless-twip($cw)"/>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="colwidths-in-twips" select="$colspec-colwidths-in-twips" tunnel="yes"/>
        <xsl:with-param name="colwidth-sum-in-twips" select="sum(($colspec-colwidths-in-twips, 0))"
          tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@colwidth[$tr:relative-table-widths]" mode="#all">
    <xsl:param name="colwidths-in-twips" as="xs:double*" tunnel="yes"/>
    <xsl:param name="colwidth-sum-in-twips" as="xs:double?" tunnel="yes"/>
    <xsl:variable name="context" select=".." as="element(*)"/>
    <!-- element(*:colspec) -->
    <xsl:variable name="current-twips" as="xs:double?"
      select="$colwidths-in-twips[position() = tr:index-of($context/../*:colspec, $context)]"/>
    <xsl:choose>
      <xsl:when test="$colwidth-sum-in-twips &gt; 0 and $tr:relative-table-widths = 'ast'">
        <xsl:attribute name="colwidth" select="tr:ast($current-twips, $colwidth-sum-in-twips)"/>
      </xsl:when>
      <xsl:when test="$colwidth-sum-in-twips &gt; 0 and $tr:relative-table-widths = 'percent'">
        <xsl:attribute name="colwidth"
          select="tr:percent($current-twips, $colwidth-sum-in-twips)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="colwidth" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>