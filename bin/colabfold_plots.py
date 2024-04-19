""" Functions to plot the results of 3D structure prediction """

from pathlib import Path
from string import ascii_uppercase, ascii_lowercase

import numpy as np
from matplotlib import pyplot as plt

alphabet_list = list(ascii_uppercase + ascii_lowercase)


def plot_predicted_alignment_error(jobname: str,
                                   num_models: int,
                                   outs: dict,
                                   result_dir: Path,
                                   show: bool = False):
    """ Plot PAE """
    plt.figure(figsize=(3 * num_models, 2), dpi=100)
    for n, (model_name, value) in enumerate(outs.items()):
        plt.subplot(1, num_models, n + 1)
        plt.title(model_name)
        plt.imshow(value["pae"], label=model_name, cmap="bwr", vmin=0, vmax=30)
        plt.colorbar()
    plt.savefig(result_dir.joinpath(jobname + "_PAE.png"))
    if show:
        plt.show()
    plt.close()


def plot_msa_v2(feature_dict, sort_lines=True, dpi=100):
    """ Plot MSA """
    seq = feature_dict["msa"][0]
    if "asym_id" in feature_dict:
        pos_s = [0]
        k = feature_dict["asym_id"][0]
        for i in feature_dict["asym_id"]:
            if i == k:
                pos_s[-1] += 1
            else: pos_s.append(1)
            k = i
    else:
        pos_s = [len(seq)]
    pos_n = np.cumsum([0] + pos_s)

    try:
        num_aln = feature_dict["num_alignments"][0]
    except:
        num_aln = feature_dict["num_alignments"]

    msa = feature_dict["msa"][:num_aln]
    gap = msa != 21
    qid = msa == seq
    gapid = np.stack([gap[:, pos_n[i]:pos_n[i + 1]].max(-1) for i in range(len(pos_s))],
                     -1)
    lines = []
    num_aln_n = []
    for g in np.unique(gapid, axis=0):
        i = np.where((gapid == g).all(axis=-1))
        qid_ = qid[i]
        gap_ = gap[i]
        seqid = np.stack(
            [qid_[:, pos_n[i]:pos_n[i + 1]].mean(-1)
             for i in range(len(pos_s))], -1).sum(-1) / (g.sum(-1) + 1e-8)
        non_gaps = gap_.astype(float)
        non_gaps[non_gaps == 0] = np.nan
        if sort_lines:
            lines_ = non_gaps[seqid.argsort()] * seqid[seqid.argsort(), None]
        else:
            lines_ = non_gaps[::-1] * seqid[::-1, None]
        num_aln_n.append(len(lines_))
        lines.append(lines_)

    num_aln_n = np.cumsum(np.append(0, num_aln_n))
    lines = np.concatenate(lines, 0)
    plt.figure(figsize=(8, 5), dpi=dpi)
    plt.title("Sequence coverage")
    plt.imshow(lines,
               interpolation='nearest',
               aspect='auto',
               cmap="rainbow_r",
               vmin=0,
               vmax=1,
               origin='lower',
               extent=(0, lines.shape[1], 0, lines.shape[0]))
    for i in pos_n[1:-1]:
        plt.plot([i, i], [0, lines.shape[0]], color="black")
    for j in num_aln_n[1:-1]:
        plt.plot([0, lines.shape[1]], [j, j], color="black")

    plt.plot((np.isnan(lines) == False).sum(0), color='black')
    plt.xlim(0, lines.shape[1])
    plt.ylim(0, lines.shape[0])
    plt.colorbar(label="Sequence identity to query")
    plt.xlabel("Positions")
    plt.ylabel("Sequences")
    return plt


def plot_msa(msa, query_sequence, seq_len_list, dpi=100):
    """ Plot MSA """
    # gather MSA info
    prev_pos = 0
    msa_parts = []
    pos_n = np.cumsum(np.append(0, [len for len in seq_len_list]))
    for i, l in enumerate(seq_len_list):
        chain_seq = np.array(query_sequence[prev_pos:prev_pos + l])
        chain_msa = np.array(msa[:, prev_pos:prev_pos + l])
        seqid = np.array([
            np.count_nonzero(chain_seq == msa_line[prev_pos:prev_pos + l]) /
            len(chain_seq) for msa_line in msa
        ])
        non_gaps = (chain_msa != 21).astype(float)
        non_gaps[non_gaps == 0] = np.nan
        msa_parts.append((non_gaps[:] * seqid[:, None]).tolist())
        prev_pos += l
    lines = []
    lines_to_sort = []
    prev_has_seq = [True] * len(seq_len_list)
    for line_num in range(len(msa_parts[0])):
        has_seq = [True] * len(seq_len_list)
        for i in range(len(seq_len_list)):
            if np.sum(~np.isnan(msa_parts[i][line_num])) == 0:
                has_seq[i] = False
        if has_seq == prev_has_seq:
            line = []
            for i in range(len(seq_len_list)):
                line += msa_parts[i][line_num]
            lines_to_sort.append(np.array(line))
        else:
            lines_to_sort = np.array(lines_to_sort)
            lines_to_sort = lines_to_sort[np.argsort(
                -np.nanmax(lines_to_sort, axis=1))]
            lines += lines_to_sort.tolist()
            lines_to_sort = []
            line = []
            for i in range(len(seq_len_list)):
                line += msa_parts[i][line_num]
            lines_to_sort.append(line)
        prev_has_seq = has_seq
    lines_to_sort = np.array(lines_to_sort)
    lines_to_sort = lines_to_sort[np.argsort(
        -np.nanmax(lines_to_sort, axis=1))]
    lines += lines_to_sort.tolist()

    # num_aln_n = np.cumsum(np.append(0, num_aln_n))
    # lines = np.concatenate(lines, 1)
    xaxis_size = len(lines[0])
    yaxis_size = len(lines)

    plt.figure(figsize=(8, 5), dpi=dpi)
    plt.title("Sequence coverage")
    plt.imshow(
        lines[::-1],
        interpolation="nearest",
        aspect="auto",
        cmap="rainbow_r",
        vmin=0,
        vmax=1,
        origin="lower",
        extent=(0, xaxis_size, 0, yaxis_size),
    )
    for i in pos_n[1:-1]:
        plt.plot([i, i], [0, yaxis_size], color="black")
    # for i in pos_n_dash[1:-1]:
    #    plt.plot([i, i], [0, lines.shape[0]], "--", color="black")
    # for j in num_aln_n[1:-1]:
    #    plt.plot([0, lines.shape[1]], [j, j], color="black")

    plt.plot((np.isnan(lines) == False).sum(0), color="black")
    plt.xlim(0, xaxis_size)
    plt.ylim(0, yaxis_size)
    plt.colorbar(label="Sequence identity to query")
    plt.xlabel("Positions")
    plt.ylabel("Sequences")

    return plt


def plot_plddt_legend(dpi=100):
    """ Plot plDDT legend """
    thresh = [
        'plDDT:', 'Very low (<50)', 'Low (60)', 'OK (70)', 'Confident (80)',
        'Very high (>90)'
    ]
    plt.figure(figsize=(1, 0.1), dpi=dpi)
    ########################################
    for c in [
            "#FFFFFF", "#FF0000", "#FFFF00", "#00FF00", "#00FFFF", "#0000FF"
    ]:
        plt.bar(0, 0, color=c)
    plt.legend(
        thresh,
        frameon=False,
        loc='center',
        ncol=6,
        handletextpad=1,
        columnspacing=1,
        markerscale=0.5,
    )
    plt.axis(False)
    return plt


def plot_confidence(plddt, pae=None, pos_s=None, dpi=100):
    """ Plot confidence """
    use_ptm = False if pae is None else True
    if use_ptm:
        plt.figure(figsize=(10, 3), dpi=dpi)
        plt.subplot(1, 2, 1)
    else:
        plt.figure(figsize=(5, 3), dpi=dpi)
    plt.title('Predicted lDDT')
    plt.plot(plddt)
    if pos_s is not None:
        pos_prev = 0
        for pos_i in pos_s[:-1]:
            pos = pos_prev + pos_i
            pos_prev += pos_i
            plt.plot([pos, pos], [0, 100], color="black")
    plt.ylim(0, 100)
    plt.ylabel('plDDT')
    plt.xlabel('position')
    if use_ptm:
        plt.subplot(1, 2, 2)
        plt.title('Predicted Aligned Error')
        pos_n = pae.shape[0]
        plt.imshow(pae, cmap="bwr", vmin=0, vmax=30, extent=(0, pos_n, pos_n, 0))
        if pos_s is not None and len(pos_s) > 1:
            plot_ticks(pos_s)
        plt.colorbar()
        plt.xlabel('Scored residue')
        plt.ylabel('Aligned residue')
    return plt


def plot_plddts(plddts, pos_s=None, dpi=100, fig=True):
    """ Plot plDDTs """
    if fig:
        plt.figure(figsize=(8, 5), dpi=dpi)
    plt.title("Predicted lDDT per position")
    for n, plddt in enumerate(plddts):
        plt.plot(plddt, label=f"rank_{n+1}")
    if pos_s is not None:
        pos_prev = 0
        for pos_i in pos_s[:-1]:
            pos = pos_prev + pos_i
            pos_prev += pos_i
            plt.plot([pos, pos], [0, 100],
                     color="black",
                     linestyle='--',
                     linewidth=1)
    plt.legend()
    plt.ylim(0, 100)
    plt.axhline(y=100, color='grey', linestyle='-', linewidth=1)
    plt.axhline(y=90, color='green', linestyle='--', linewidth=1)
    plt.axhline(y=70, color='orange', linestyle='--', linewidth=1)
    plt.axhline(y=50, color='red', linestyle='--', linewidth=1)
    plt.ylabel("Predicted lDDT")
    plt.xlabel("Residue")
    return plt


def plot_paes(paes, pos_s=None, dpi=100, fig=True):
    """ Plot PAEs """
    num_models = len(paes)
    if fig:
        plt.figure(figsize=(3 * num_models, 2), dpi=dpi)
    for n, pae in enumerate(paes):
        axes = plt.subplot(1, num_models, n + 1)
        plot_pae(pae, axes, caption=f"rank_{n+1}", pos_s=pos_s)
    return plt


def plot_pae(pae,
             axes,
             caption='PAE',
             caption_pad=None,
             pos_s=None,
             colorkey_size=1.0):
    """ Plot PAE """
    axes.set_title(caption, pad=caption_pad)
    pos_n = pae.shape[0]
    image = axes.imshow(pae,
                        cmap="bwr",
                        vmin=0,
                        vmax=30,
                        extent=(0, pos_n, pos_n, 0))
    if pos_s is not None and len(pos_s) > 1:
        plot_ticks(pos_s, axes=axes)
    plt.colorbar(mappable=image, ax=axes, shrink=colorkey_size)


def plot_adjs(adjs, pos_s=None, dpi=100, fig=True):
    """ Plot adjs """
    num_models = len(adjs)
    if fig:
        plt.figure(figsize=(3 * num_models, 2), dpi=dpi)
    for n, adj in enumerate(adjs):
        plt.subplot(1, num_models, n + 1)
        plt.title(f"rank_{n+1}")
        pos_n = adj.shape[0]
        plt.imshow(adj, cmap="binary", vmin=0, vmax=1, extent=(0, pos_n, pos_n, 0))
        if pos_s is not None and len(pos_s) > 1:
            plot_ticks(pos_s)
        plt.colorbar()
    return plt


def plot_ticks(pos_s, axes=None):
    """ Plot ticks """
    if axes is None:
        axes = plt.gca()
    pos_n = sum(pos_s)
    pos_prev = 0
    for pos_i in pos_s[:-1]:
        pos = pos_prev + pos_i
        pos_prev += pos_i
        plt.plot([0, pos_n], [pos, pos], color="black", linestyle='--', linewidth=1)
        plt.plot([pos, pos], [0, pos_n], color="black", linestyle='--', linewidth=1)
    ticks = np.cumsum([0] + pos_s)
    ticks = (ticks[1:] + ticks[:-1]) / 2
    axes.set_yticks(ticks)
    axes.set_yticklabels(alphabet_list[:len(ticks)])


def plot_dists(dists, pos_s=None, dpi=100, fig=True):
    """ Plot dists """
    num_models = len(dists)
    if fig:
        plt.figure(figsize=(3 * num_models, 2), dpi=dpi)
    for n, dist in enumerate(dists):
        plt.subplot(1, num_models, n + 1)
        plt.title(f"rank_{n+1}")
        pos_n = dist.shape[0]
        plt.imshow(dist, extent=(0, pos_n, pos_n, 0))
        if pos_s is not None and len(pos_s) > 1:
            plot_ticks(pos_s)
        plt.colorbar()
    return plt
