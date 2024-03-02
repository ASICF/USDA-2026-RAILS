import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Icon,
  Tab,
  Segment,
  Divider,
  Label,
  Breadcrumb,
  Form,
  Table,
  Header,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import axios from "axios";
import { tableSortReducer } from "../Shared/TableSort";

export default function ExportProductionVectorMetadata({ active, token }) {
  const [message, setMessage] = useState(null);

  console.log("ExportVectorMetadata", {
    active,
  });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Export</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Vector Metadata</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Production</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      <VectorMetadataList record={active} token={token} />
    </div>
  );

  function renderMessage() {
    if (!message) return null;

    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  }
}

function VectorMetadataList({ record, token }) {
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: record,
    direction: null,
  });
  const { column, data, direction } = state;

  const exportVectorMetadatum = (record) => {
    console.log(record);

    axios
      .post("/execute_export_production_vector_metadata", {
        project: record.project,
        state_id: record.state_id,
        authenticity_token: token,
      })
      .then((res) => {
        console.log(res);

        if (res.data.history_id) {
            window.open(`/download_production_vector_metadata/${res.data.history_id}`, "_blank");
        }

      });
  };

  return (
    <Fragment>
      <Divider />
      <Table textAlign="center" celled sortable>
        <Table.Header>
          <Table.Row style={{ cursor: "pointer" }}>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "state" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "state" })}
            >
              State
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "count" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "count" })}
            >
              Count
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "min_flight_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "min_flight_date" })
              }
            >
              Minimum Flight Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "max_flight_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "max_flight_date" })
              }
            >
              Maximum Flight Date
            </Table.HeaderCell>
            <Table.HeaderCell></Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.state}</Table.Cell>
                <Table.Cell>{record.count}</Table.Cell>
                <Table.Cell>
                  {moment(record.min_flight_date, "YYYY MM-DD").format(
                    "MM/DD/YYYY"
                  )}
                </Table.Cell>
                <Table.Cell>
                  {moment(record.max_flight_date, "YYYY MM-DD").format(
                    "MM/DD/YYYY"
                  )}
                </Table.Cell>

                <Table.Cell>
                  <Button secondary icon>
                    <Icon
                      name="download"
                      onClick={() => exportVectorMetadatum(record)}
                    />
                  </Button>
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
      <br />
    </Fragment>
  );
}
