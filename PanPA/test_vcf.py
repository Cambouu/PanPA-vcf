import subprocess
import sys


GFA = """\
S\t1\tMS\tLN:i:2\tSP:i:0
L\t1\t+\t4\t+\t0M
S\t2\tM\tLN:i:1\tSP:i:1
L\t2\t+\t4\t+\t0M
S\t4\tE\tLN:i:1\tSP:i:2
L\t4\t+\t5\t+\t0M
L\t4\t+\t6\t+\t0M
S\t5\tPTPE\tLN:i:4\tSP:i:3
L\t5\t+\t14\t+\t0M
S\t6\tT\tLN:i:1\tSP:i:3
L\t6\t+\t8\t+\t0M
L\t6\t+\t10\t+\t0M
S\t8\tQST\tLN:i:3\tSP:i:4
L\t8\t+\t14\t+\t0M
S\t10\tMA\tLN:i:2\tSP:i:5
S\t14\tQ\tLN:i:1\tSP:i:7
P\tseq3\t1+,4+,6+,8+,14+\t0M,0M,0M,0M
P\tseq1\t2+,4+,5+,14+\t0M,0M,0M
P\tseq2\t6+,10+\t0M
"""

QUERIES = """\
>ins3
MERPTPEQ
>del5
MSETA
"""


def test_vcf_keeps_deletion_from_off_reference_node(tmp_path):
    graph = tmp_path / "plot1.aln.gfa"
    queries = tmp_path / "query1.fasta"
    gaf = tmp_path / "output.gaf"
    log = tmp_path / "log.log"
    graph.write_text(GFA)
    queries.write_text(QUERIES)

    subprocess.run(
        [
            sys.executable,
            "-m",
            "PanPA.main",
            "--log_file",
            str(log),
            "align_single",
            "-g",
            str(graph),
            "-r",
            str(queries),
            "-o",
            str(gaf),
            "--vcf",
            "--min_id_score",
            "0.0",
        ],
        check=True,
    )

    records = [
        line.split("\t")
        for line in gaf.with_suffix(".vcf").read_text().splitlines()
        if line and not line.startswith("#")
    ]

    assert any(
        fields[1] == "5"
        and fields[3] == "QS"
        and fields[4] == "Q"
        and fields[7] == "VC=DEL"
        for fields in records
    )
